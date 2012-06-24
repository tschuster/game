namespace :daemon do
  task :restart do
    run "svc -du ~/service/job-daemon"
    run "svc -du ~/service/ai-daemon"
  end
end

before "deploy:cleanup", "daemon:restart"