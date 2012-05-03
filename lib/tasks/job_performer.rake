namespace :jobs do

  task :perform => :environment do
    while true do
      Action.incomplete.to_be_completed.each do |action|
        action.perform! 
      end
      puts sleep(10)
    end
  end
end