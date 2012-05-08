include ActionView::Helpers::NumberHelper
class Notification < ActiveRecord::Base
  belongs_to :user

  symbolize :klass, :in => [:news, :attack_success_victim, :attack_success_attacker, :attack_failed_victim, :attack_failed_attacker, :attack], :scopes => true

  scope :latest_10, {
    :order => "created_at DESC",
    :limit => 10
  }

  scope :unread, where(:is_new => true)

  class << self
    def create_for(klass, user, options = {})
      
      message = case klass
      when :attack_success_victim
        "<p>You have been attacked by #{options[:attacker].nickname}!</p>#{number_to_currency(options[:value])} have been stolen."
      when :attack_success_attacker
        "<p>You have successfully attacked #{options[:victim].nickname}!</p> You have stolen #{number_to_currency(options[:value])}."
      when :attack_failed_victim
        "<p>You have been attacked by #{options[:attacker].nickname} but your firewall kept you safe!</p>"
      when :attack_failed_attacker
        "<p>You failed to attack #{options[:victim].nickname}!</p> Your systems are damadged and rebooting."
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