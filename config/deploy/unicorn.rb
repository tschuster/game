namespace :unicorn do
  task :start, :roles => :app, :except => { :no_release => true } do
    run "cd #{current_path} && bundle exec unicorn_rails  -E #{rails_env} -D --listen 127.0.0.1:10301"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do
    run "if [ -e #{unicorn_pid} ]; then kill `cat #{unicorn_pid}`; fi"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
end

# before 'deploy:update_code', 'resque:stop_workers'
after  'deploy:update_code', 'unicorn:restart'
