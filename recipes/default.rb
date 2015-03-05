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

python_webapp whats-fresh do
  path '/opt/whats_fresh'
  owner 'whats_fresh'
  group 'whats_fresh'

  repository 'github.com/osu-cass/whats-fresh-api.git'
  revision :master

  gunicorn_port 8000

  config_template 'config.yml.erb'
  config_destination '/opt/whats_fresh/config/config.yml'
  config_vars (
    host: pg['host'],
    port: pg['port'],
    username: pg['user'],
    password: pg['pass'],
    db_name: pg['database_name'],
    secret_key: pg['secret_key']
  )
end


nginx_app 'whats_fresh' do
  template 'whats_fresh.conf.erb'
  cookbook 'whats-fresh'
end

node.default['nginx']['default_site_enabled'] = false

selinux_policy_boolean 'httpd_can_network_connect' do
  value true
  notifies :start, 'service[nginx]', :immediate
end
