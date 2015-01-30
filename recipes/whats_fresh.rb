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
node.default['whats_fresh']['application_dir'] = '/opt/whats_fresh'
node.default['whats_fresh']['repository'] = 'https://github.com/osu-cass/whats-fresh-api'
node.default['whats_fresh']['nginx_name'] = 'whats_fresh'

# To avoid port collision, use port 8080 for What's Fresh
# and 8000 for Working Waterfronts
node.default['whats_fresh']['gunicorn_port'] = 8080

include_recipe 'whats-fresh::_common'
