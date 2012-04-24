# taken and adapted from bundler
namespace :bundle do
  task :install do
    run "bundle install --gemfile #{release_path}/Gemfile --path #{fetch(:bundle_dir, "#{shared_path}/bundle")} --deployment --without development test cucumber"
  end
end

#after "deploy:update_code", "bundle:install"