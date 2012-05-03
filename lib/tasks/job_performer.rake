namespace :jobs do

  task :perform => :environment do
    while true do
      Action.where("completed = ? AND completed_at <= ?", false, DateTime.now).each do |action|
        puts "performing action #{action.id}"
        action.perform!
      end
      sleep(10)
    end
  end
end