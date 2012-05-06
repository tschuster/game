namespace :rvm do
  task :trust_rvmrc do
    run "rvm rvmrc trust #{release_path}"
  end

  task :trust_rvmrc_in_current_path do
    run "rvm rvmrc trust #{current_path}"
  end
end
 
after "deploy:update_code", "rvm:trust_rvmrc"
after "deploy:create_symlink", "rvm:trust_rvmrc_in_current_path"