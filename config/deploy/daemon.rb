namespace :daemon do
  task :restart do
    run "svc -du ~/service/job-daemon"
  end
end

#before "deploy:cleanup", "daemon:restart"