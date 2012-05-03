namespace :daemon do
  task :restart do
    run "svc -du ~/service/job-daemon"
  end
end

after "deploy:update_code", "daemon:restart"