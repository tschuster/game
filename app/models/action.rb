# encoding: utf-8
class Action < ActiveRecord::Base
  belongs_to :user
  belongs_to :job
  belongs_to :target, :polymorphic => true

  # Exception-Klasse
  class InvalidTypeException < StandardError
  end
  class ImplementationMissingException < StandardError
  end

  validates_presence_of :completed_at

  scope :incomplete, :conditions => { :completed => false }

  scope :to_be_completed, :conditions => [ "completed_at <= ?", DateTime.now ]

  scope :current_for_user, lambda { |current_user|
    {
      :conditions => { :completed => false, :user_id => current_user.id },
      :limit      => 1
    }
  }

  TYPE_BOTNET_EVOLVE    = 101
  TYPE_BOTNET_BUY       = 102
  TYPE_HACKING_EVOLVE   = 103
  TYPE_HACKING_BUY      = 104
  TYPE_DEFENSE_EVOLVE   = 105
  TYPE_DEFENSE_BUY      = 106
  TYPE_PERFORM_JOB      = 201
  TYPE_ATTACK_USER      = 301
  TYPE_ATTACK_COMPANY   = 302
  TYPE_ATTACK_USER_DDOS = 303
  TYPE_ARREST           = 401
  TYPE_SYSTEM_CRASH     = 402
  TYPE_DDOS_CRASH       = 403

  def perform!
    # eigenes Botnet erweitern
    if type_id == Action::TYPE_BOTNET_EVOLVE
      user.evolve_botnet

    # Botnet-Erweiterung dazukaufen
    elsif type_id == Action::TYPE_BOTNET_BUY
      user.buy_botnet

    # eigene Verteidigung erweitern
    elsif type_id == Action::TYPE_DEFENSE_EVOLVE
      user.evolve_defense

    # Verteidigung dazukaufen
    elsif type_id == Action::TYPE_DEFENSE_BUY
      user.buy_defense

    # Hacking-Skill erweitern
    elsif type_id == Action::TYPE_HACKING_EVOLVE
      user.evolve_hacking

    # Hacking-Skill dazukaufen
    elsif type_id == Action::TYPE_HACKING_BUY
      user.buy_hacking

    # Job ausführen
    elsif type_id == Action::TYPE_PERFORM_JOB
      job.perform!

    # User angreifen
    elsif type_id == Action::TYPE_ATTACK_USER
      user.attack(target, :hack)

    # User dDoS angreifen
    elsif type_id == Action::TYPE_ATTACK_USER_DDOS
      user.attack(target, :ddos)

    # Sperre aufheben
    elsif (type_id == Action::TYPE_SYSTEM_CRASH || type_id == Action::TYPE_DDOS_CRASH )
      # n/a

    else
      raise Action::InvalidTypeException.new("Typ '#{type_id.to_s}' ungültig")
    end
    complete!
  end

  def complete!
    update_attribute(:completed, true)
  end

  def readable_type
    case type_id
    when Action::TYPE_BOTNET_EVOLVE
      "Evolve Botnet"
    when Action::TYPE_BOTNET_BUY
      "Buy Botnet"
    when Action::TYPE_HACKING_EVOLVE
      "Evolve Hacking Skill"
    when Action::TYPE_HACKING_BUY
      "Buy Hacking Skill"
    when Action::TYPE_DEFENSE_EVOLVE
      "Evolve Defense"
    when Action::TYPE_DEFENSE_BUY
      "Buy Defense"
    when Action::TYPE_PERFORM_JOB
      "Performing Job"
    when Action::TYPE_ATTACK_USER
      "Performing Hacking-Attack on #{target.present? ? target.nickname : "another Hacker"}"
    when Action::TYPE_ATTACK_USER_DDOS
      "Performing dDoS-Attack on #{target.present? ? target.nickname : "another Hacker"}"
    when Action::TYPE_DDOS_CRASH
      "Rebooting System after dDoS-Attack"
    when Action::TYPE_SYSTEM_CRASH
      "Rebooting System"
    else
      raise Action::InvalidTypeException.new("Typ '#{type_id.to_s}' ungültig")
    end
  end

  def time_remaining
    [completed_at - DateTime.now, 0].max
  end

  def can_be_canceled?
    type_id != Action::TYPE_SYSTEM_CRASH && type_id != Action::TYPE_DDOS_CRASH
  end

  class << self

    # eine neue Action für einen User zur Abarbeitung anlegen
    def add_for_user(action, current_user)
      return if current_user.has_incomplete_actions?
      target_type = nil

      # Validierungen
      will_be_completed_at = if action.type_id == Action::TYPE_BOTNET_EVOLVE
        DateTime.now + current_user.next_botnet_ratio_time.seconds

      elsif action.type_id == Action::TYPE_BOTNET_BUY
        DateTime.now

      elsif action.type_id == Action::TYPE_DEFENSE_EVOLVE
        DateTime.now + current_user.next_defense_ratio_time.seconds

      elsif action.type_id == Action::TYPE_DEFENSE_BUY
        DateTime.now

      elsif action.type_id == Action::TYPE_HACKING_EVOLVE
        DateTime.now + current_user.next_hacking_ratio_time.seconds

      elsif action.type_id == Action::TYPE_HACKING_BUY
        DateTime.now

      elsif action.type_id == Action::TYPE_PERFORM_JOB
        DateTime.now + Job.find(action[:job_id]).duration_for(current_user).seconds

      elsif action.type_id == Action::TYPE_ATTACK_USER
        target = User.where(:id => action.target_id).first
        return if target.blank?
        target_type = "User"
        DateTime.now + current_user.time_to_attack(target, :hack).seconds

      elsif action.type_id == Action::TYPE_ATTACK_USER_DDOS
        target = User.where(:id => action.target_id).first
        return if target.blank?
        target_type = "User"
        DateTime.now + current_user.time_to_attack(target, :ddos).seconds

      else
        raise Action::InvalidTypeException.new("Typ '#{action.type_id}' ungültig")
      end
      result = Action.create(
        :type_id      => action.type_id,
        :job_id       => action.job_id,
        :user_id      => current_user.id,
        :target_id    => action.target_id,
        :target_type  => target_type,
        :completed_at => will_be_completed_at,
        :completed    => false
      )
      result
    end
  end
end