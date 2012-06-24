namespace :ai do

  task :perform => :environment do
    ai_player = AiPlayer.find(20)
    while true do
      ai_player.perform_action!
      sleep(5)
    end
  end
end