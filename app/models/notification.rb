include ActionView::Helpers::NumberHelper
class Notification < ActiveRecord::Base
  belongs_to :user

  symbolize :klass, :in => [
    :news, 
    :attack_success_victim, 
    :attack_success_attacker, 
    :attack_failed_victim, 
    :attack_failed_attacker, 
    :attack,
    :attack_company,
    :ddos_success_victim, 
    :ddos_success_attacker, 
    :ddos_failed_victim, 
    :ddos_failed_attacker, 
    :attack_company_success_attacker, 
    :attack_company_success_previous_owner, 
    :attack_company_failed_owner,
    :attack_company_failed_attacker
  ], :scopes => true

  scope :latest_10, {
    :order => "created_at DESC",
    :limit => 10
  }

  scope :unread, where(:is_new => true)

  class << self
    def create_for(klass, user, options = {})
      
      message = case klass
      when :attack_success_victim
        "<p>You have been hacked by #{options[:attacker].nickname}!</p>#{number_to_currency(options[:value])} have been stolen."
      when :attack_success_attacker
        "<p>You have successfully hacked #{options[:victim].nickname}!</p> You have stolen #{number_to_currency(options[:value])}."
      when :attack_company_success_attacker
        "<p>You have successfully taken control over #{options[:victim].name}!</p> You will now receive #{number_to_currency(options[:value])} every hour."
      when :attack_company_success_previous_owner
        "<p>The company #{options[:victim].name} wich you controlled was overtaken by #{options[:attacker].nickname}!</p>"
      when :attack_failed_victim
        "<p>You have been hacked by #{options[:attacker].nickname} but your firewall kept you safe!</p>"
      when :attack_failed_attacker, :ddos_failed_attacker
        "<p>You failed to hack #{options[:victim].nickname}!</p> Your systems are damadged and rebooting."
      when :attack_company_failed_owner
        "<p>The company #{options[:victim].name} wich you control has repelled an attacked by #{options[:attacker].nickname}!</p> The company's defenses have been upgraded."
      when :attack_company_failed_attacker
        "<p>You failed to hack #{options[:victim].name}!</p> The company's defenses have been upgraded. Your systems are damadged and rebooting."
      when :ddos_success_victim
        "<p>You have been dDoS-attacked by #{options[:attacker].nickname}!</p>Your systems are damadged and rebooting. Your current action has been canceled."
      when :ddos_success_attacker
        "<p>You have successfully attacked #{options[:victim].nickname} with a dDoS-attack!</p>"
      when :ddos_failed_victim
        "<p>You have been dDoS-attacked by #{options[:attacker].nickname} but your firewall kept you safe!</p>"
      when :news
        options[:message]
      end

      Notification.create(
        :user => user,
        :from_user_id => options[:from_user_id],
        :klass => klass,
        :message => message,
        :is_new => true
      )
    end

    def create_for_all!(klass, options = {})
      message = case klass
      when :attack
        "#{options[:victim].nickname} was attacked by #{options[:attacker].nickname}!"
      when :attack_company
        if options[:success]
          "#{options[:attacker].nickname} has taken control over #{options[:victim].name}"
        else
          "#{options[:victim].name} was attacked by #{options[:attacker].nickname}!"
        end
      when :news
        options[:message]
      end

      User.all.each do |user|
        Notification.create!(
          :user => user,
          :from_user_id => options[:from_user_id],
          :klass => :news,
          :message => message,
          :is_new => true
        )
      end
    end
  end
end