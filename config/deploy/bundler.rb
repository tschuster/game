# taken and adapted from bundler
namespace :bundle do
  task :install do
    run "cd #{current_path} && bundle install --deployment --without development test cucumber"
  end
end

#after "rvm:trust_rvmrc", "bundle:install"