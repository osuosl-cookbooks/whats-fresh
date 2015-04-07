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

include_recipe 'build-essential'
include_recipe 'git'
include_recipe 'python'
include_recipe 'postgresql::client'
include_recipe 'database::postgresql'
include_recipe 'postgis'
include_recipe 'osl-nginx'

pg = Chef::EncryptedDataBagItem.load('whats_fresh',
                                     node['whats_fresh']['databag'])

magic_shell_environment 'WF_CONFIG_DIR' do
  value node['whats_fresh']['config_dir']
end

directory node['whats_fresh']['config_dir'] do
  owner node['whats_fresh']['venv_owner']
  group node['whats_fresh']['venv_group']
  recursive true
end

python_webapp 'whats_fresh' do
  create_user true
  path node['whats_fresh']['application_dir']
  owner node['whats_fresh']['venv_owner']
  group node['whats_fresh']['venv_group']

  repository node['whats_fresh']['repository']
  revision node['whats_fresh']['git_branch']

  config_template 'config.yml.erb'
  config_destination "#{node['whats_fresh']['config_dir']}/config.yml"
  config_vars(
    host: pg['host'],
    port: pg['port'],
    username: pg['user'],
    password: pg['pass'],
    db_name: pg['database_name'],
    secret_key: pg['secret_key'],

    debug: node['whats_fresh']['debug'],
    application_dir: node['whats_fresh']['application_dir']

  )
  django_migrate true
  django_collectstatic true
  interpreter 'python2.7'

  gunicorn_port node['whats_fresh']['gunicorn_port']
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
