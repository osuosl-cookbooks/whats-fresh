ruby_block "whats_fresh_monkey_patch" do
  block do
    ::Chef::Provider::ApplicationPythonDjango.class_eval do
      def action_before_compile
        include_recipe 'python'
        new_resource.migration_command "#{::File.join(new_resource.virtualenv, "bin", "python")} #{node['whats_fresh']['subdirectory']}manage.py syncdb --noinput" if !new_resource.migration_command
        new_resource.symlink_before_migrate.update({
new_resource.local_settings_base => new_resource.local_settings_file,})
      end
      def action_before_symlink
        if new_resource.collectstatic
          cmd = new_resource.collectstatic.is_a?(String) ? new_resource.collectstatic : "collectstatic --noi\
nput"
          execute "#{::File.join(new_resource.virtualenv, "bin", "python")} #{node['whats_fresh']['subdirectory']}manage.py #{cmd}" do
            user new_resource.owner
            group new_resource.group
            cwd new_resource.release_path
          end
        end
        ruby_block "remove_run_migrations" do
          block do
            if node.role?("#{new_resource.application.name}_run_migrations")
              Chef::Log.info("Migrations were run, removing role[#{new_resource.name}_run_migrations]")
              node.run_list.remove("role[#{new_resource.name}_run_migrations]")
            end
          end
        end
      end
    end
  end
    ::Chef::Provider::ApplicationPythonGunicorn.class_eval do
      def action_before_deploy
        gunicorn_config "#{new_resource.application.path}/shared/gunicorn_config.py" do
          action :create
          template new_resource.settings_template || 'gunicorn.py.erb'
          cookbook new_resource.settings_template ? new_resource.cookbook_name.to_s : 'gunicorn'
          #if new_resource.socket_path
          #  listen_uri = "unix:#{new_resource.socket_path}"
          #else
          listen_uri = "#{new_resource.host}:#{new_resource.port}"
          #end
          listen listen_uri
          backlog new_resource.backlog
          worker_processes new_resource.workers
          worker_class new_resource.worker_class.to_s
          #worker_connections
          worker_max_requests new_resource.max_requests
          worker_timeout new_resource.timeout
          worker_keepalive new_resource.keepalive
          #debug
          #trace
          preload_app new_resource.preload_app
          #daemon
          pid new_resource.pidfile
          #umask
          #logfile
          #loglevel
          #proc_name
        end

        supervisor_service new_resource.application.name do
          action :enable
          if new_resource.environment
            environment new_resource.environment
          end
          django_resource = new_resource.application.sub_resources.select{|res| res.type == :django}.first
          base_command = "#{::File.join(django_resource.virtualenv, "bin", "gunicorn")} #{node['whats_fresh']['application_name']}.wsgi:application"
          command "#{base_command} -c #{new_resource.application.path}/shared/gunicorn_config.py"
          directory new_resource.directory.nil? ? ::File.join(new_resource.path, "current", node['whats_fresh']['subdirectory']) : new_resource.directory
          autostart new_resource.autostart
          user new_resource.owner
        end
      end
    end
  end
