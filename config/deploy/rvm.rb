namespace :rvm do
  task :trust_rvmrc do
    run "rvm rvmrc trust #{release_path}"
  end
end

before "deploy:finalize_update", "rvm:trust_rvmrc"