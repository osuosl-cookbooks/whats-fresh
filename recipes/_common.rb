#
# Cookbook Name:: whats-fresh
# Recipe:: default
#
# Copyright 2014, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'whats-fresh::_centos' if platform_family?('rhel')
include_recipe 'build-essential'
include_recipe 'git'
include_recipe 'python'
include_recipe 'postgresql::client'
include_recipe 'database::postgresql'
include_recipe 'postgis'
include_recipe 'osl-nginx'

magic_shell_environment 'PATH' do
  value "/usr/pgsql-9.3/bin:$PATH"
end

pg = Chef::EncryptedDataBagItem.load('whats_fresh',
                                     node['whats_fresh']['databag'])

if node['whats_fresh']['make_db']
  postgresql_connection_info = {
    host: pg['host'],
    port: pg['port'],
    username: pg['root_user'],
    password: pg['root_pass']
  }

  # Create Postgres database
  database pg['database_name'] do
    connection postgresql_connection_info
    provider Chef::Provider::Database::Postgresql
    action :create
  end

  # Add Postgis extension to database
  bash 'create Postgis extension in database' do
    code <<-EOH
      runuser -l postgres -c 'psql #{pg['database_name']} -c "CREATE EXTENSION IF NOT EXISTS postgis;"'
    EOH
  end

  postgresql_database_user pg['user'] do
    connection postgresql_connection_info
    database_name pg['database_name']
    password pg['pass']
    privileges [:all]
    action :create
  end
end

include_recipe 'whats-fresh::_monkey_patch'

%w(shared static media config).each do |path|
  directory "#{node['whats_fresh']['application_dir']}/#{path}" do
    owner node['whats_fresh']['venv_owner']
    group node['whats_fresh']['venv_group']
    mode 0755
    recursive true
  end
end

template "#{node['whats_fresh']['application_dir']}/config/config.yml" do
  source 'config.yml.erb'
  owner node['whats_fresh']['venv_owner']
  group node['whats_fresh']['venv_group']
  variables(
    host: pg['host'],
    port: pg['port'],
    username: pg['user'],
    password: pg['pass'],
    db_name: pg['database_name'],
    secret_key: pg['secret_key']
  )
end

application 'whats_fresh' do
  path node['whats_fresh']['application_dir']
  owner node['whats_fresh']['venv_owner']
  group node['whats_fresh']['venv_group']
  repository node['whats_fresh']['repository']
  revision node['whats_fresh']['git_branch']
  migrate true

  django do
    requirements 'requirements.txt'
    debug node['whats_fresh']['debug']
  end

  gunicorn do
    app_module :django
    autostart true
    port node['whats_fresh']['gunicorn_port']
    loglevel 'debug'
  end
end

nginx_app 'whats_fresh' do
  template 'whats_fresh.conf.erb'
  cookbook 'whats-fresh'
end

node.default['nginx']['default_site_enabled'] = false

# Collect static files (css, js, etc)
python_path = File.join(node['whats_fresh']['application_dir'], 'shared',
                        'env', 'bin', 'python')
manage_py_path = File.join(node['whats_fresh']['application_dir'],
                           'current', node['whats_fresh']['subdirectory'],
                           'manage.py')

execute 'collect static files' do
  command "#{python_path} #{manage_py_path} collectstatic --noi"
  user node['whats_fresh']['venv_owner']
  group node['whats_fresh']['venv_group']
end
