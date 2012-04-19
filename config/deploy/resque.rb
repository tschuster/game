namespace :resque do
  task :start_workers, :roles => :queue do
    rake "resque:start_workers"
  end

  task :stop_workers, :roles => :queue do
    rake "resque:stop_workers"
  end

  task :kill_workers, :roles => :queue do
    rake "resque:kill_workers"
  end

  def rake(*tasks)
    rails_env = fetch(:rails_env, "production")
    rake = fetch(:rake, "rake")
    tasks.each do |t|
      run "if [ -d #{release_path} ]; then cd #{release_path}; else cd #{current_path}; fi; #{rake} RAILS_ENV=#{rails_env} #{t}"
    end
  end
end

# before 'deploy:update_code', 'resque:stop_workers'
# after  'deploy:update_code', 'resque:start_workers'