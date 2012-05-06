# taken and adapted from bundler
namespace :bundle do
  task :install do
    #run "cd #{current_path} && bundle install --deployment --without development test cucumber"
    run [
        "source #{rvm_path} && cd #{release_path} &&",
        "bundle install",
        "--gemfile #{release_path}/Gemfile",
        #"--path #{shared_path}/bundle",
        #"--deployment --quiet",
        "--without development test"
      ].join(" ")
  end
end

after "rvm:trust_rvmrc", "bundle:install"