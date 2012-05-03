# taken and adapted from bundler
namespace :bundle do
  task :install do
    run "bundle install --deployment --without development test cucumber"
  end
end

after "deploy:update_code", "bundle:install"