# taken and adapted from bundler
namespace :bundle do
  task :install do
    run [
        "cd #{release_path} &&",
        "bundle install",
        "--gemfile #{release_path}/Gemfile",
        "--without development test"
      ].join(" ")
  end
end

after "rvm:trust_rvmrc", "bundle:install"