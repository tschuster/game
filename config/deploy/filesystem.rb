namespace :deploy do
  desc <<-DESC
    Symlink shared directories and files.
  DESC
  task :symlink_dependencies do
    shared_directories_to_create = fetch(:shared_directories_to_create, [])
    directories_to_create        = fetch(:directories_to_create, [])
    files_to_delete              = fetch(:files_to_delete, [])
    files_to_link                = fetch(:files_to_link, {})
    chmods_to_set                = fetch(:chmods_to_set, [])

    # TODO: the shared directories should be created in a separate
    # "setup" task - no need to do it everytime a deployment happens
    shared_directories_to_create.each { |directory| run "mkdir -p #{directory}" }

    directories_to_create.each        { |directory| run "mkdir -p #{directory}" }
    files_to_delete.each              { |file| run "rm #{file}" }
    files_to_link.each                { |source, target| run "ln -s #{source} #{target}"}
    chmods_to_set.each                { |target, chmod| run "chmod #{chmod} #{target}" }
  end

  task :cleanup, :except => { :no_release => true } do
    count = fetch(:keep_releases, 5).to_i
    local_releases = capture("ls -xt #{releases_path}").split.reverse
    if count >= local_releases.length
      logger.important "no old releases to clean up"
    else
      logger.info "keeping #{count} of #{local_releases.length} deployed releases"
      directories = (local_releases - local_releases.last(count)).map { |release|
        File.join(releases_path, release) }.join(" ")

      run "rm -rf #{directories}"
    end
  end
end

before 'deploy:finalize_update', 'deploy:symlink_dependencies'
after 'deploy:create_symlink', 'deploy:cleanup'