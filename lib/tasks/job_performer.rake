namespace :jobs do

  task perform: :environment do
    while true do
      Action.where("completed = ? AND completed_at <= ?", false, DateTime.now).each do |action|
        puts "performing action #{action.id}"
        action.perform!
      end
      Company.where("user_id IS NOT NULL").each do |company|
        company.payout!
      end
      sleep(10)
    end
  end
end