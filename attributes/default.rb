default['whats_fresh']['application_dir'] = '/opt/whats_fresh'
default['whats_fresh']['config_dir'] = '/opt/whats_fresh/config'
default['whats_fresh']['venv_owner'] = 'root'
default['whats_fresh']['venv_group'] = 'root'
default['whats_fresh']['databag'] = 'pgsql'
default['postgis']['template_name'] = nil

default['whats_fresh']['debug'] = false
default['whats_fresh']['git_branch'] = 'develop'
default['whats_fresh']['repository'] = 'https://github.com/osu-cass/whats-fresh-api'

default['whats_fresh']['server_name'] = node['fqdn']
default['whats_fresh']['gunicorn_port'] = 8080
default['whats_fresh']['access_log'] = "#{node['nginx']['log_dir']}" \
  '/whats_fresh/access.log'
default['whats_fresh']['error_log'] = "#{node['nginx']['log_dir']}" \
  '/whats_fresh/error.log'
default['whats_fresh']['subdirectory'] = '' # add trailing slash if in a subdir

override['python']['pip_location'] = "#{node['python']['prefix_dir']}" \
  '/bin/pip2.7'

if platform_family?('rhel')
  override['nginx']['default_site_enabled'] = false
  override['postgresql']['enable_pgdg_yum'] = true
  override['postgresql']['version'] = '9.3'
  override['postgresql']['server']['packages'] = %W(
    postgresql#{node['postgresql']['version'].gsub('.', '')}-server)
  override['postgresql']['client']['packages'] = %W(
    postgresql#{node['postgresql']['version'].gsub('.', '')}-devel
    libpqxx-devel)
  override['postgresql']['server']['service_name'] = 'postgresql-9.3'
end

default['postgis']['package'] = 'postgis2_93'

override['build-essential']['compile_time'] = true
