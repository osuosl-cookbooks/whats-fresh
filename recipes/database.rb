#
# Cookbook Name:: whats-fresh
# Recipe:: database
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

include_recipe 'postgresql::client'
include_recipe 'database::postgresql'
include_recipe 'postgis'

pg = Chef::EncryptedDataBagItem.load('whats_fresh',
                                     node['whats_fresh']['databag'])

magic_shell_environment 'PATH' do
  value '/usr/pgsql-9.3/bin:$PATH'
end

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
    runuser -l postgres -c 'psql #{pg['database_name']} -c \
    "CREATE EXTENSION IF NOT EXISTS postgis;"'
  EOH
end

postgresql_database_user pg['user'] do
  connection postgresql_connection_info
  database_name pg['database_name']
  password pg['pass']
  privileges [:all]
  action :create
end
