# encoding: utf-8
class Action < ActiveRecord::Base
  belongs_to :user
  belongs_to :job
  belongs_to :target, polymorphic: true

  # Exception-Klasse
  class InvalidTypeException < StandardError
  end
  class ImplementationMissingException < StandardError
  end

  validates_presence_of :completed_at

  scope :incomplete, conditions: { completed: false }

  scope :to_be_completed, conditions: [ "completed_at <= ?", DateTime.now ]

  scope :current_for_user, lambda { |current_user|
    {
      conditions: { completed: false, user_id: current_user.id },
      limit:     1
    }
  }

  TYPE_BOTNET_EVOLVE          = 101
  TYPE_BOTNET_BUY             = 102
  TYPE_HACKING_EVOLVE         = 103
  TYPE_HACKING_BUY            = 104
  TYPE_DEFENSE_EVOLVE         = 105
  TYPE_DEFENSE_BUY            = 106
  TYPE_PERFORM_JOB            = 201
  TYPE_ATTACK_USER            = 301
  TYPE_ATTACK_COMPANY         = 302
  TYPE_ATTACK_USER_DDOS       = 303
  TYPE_ARREST                 = 401
  TYPE_SYSTEM_CRASH           = 402
  TYPE_DDOS_CRASH             = 403
  TYPE_COMPANY_INCOME_EVOLVE  = 501
  TYPE_COMPANY_INCOME_BUY     = 502
  TYPE_COMPANY_DEFENSE_EVOLVE = 503
  TYPE_COMPANY_DEFENSE_BUY    = 504

  def perform!

    # eigenes Botnet erweitern
    result = if type_id == Action::TYPE_BOTNET_EVOLVE
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

    # User oder Firma angreifen
    elsif type_id == Action::TYPE_ATTACK_USER || type_id == Action::TYPE_ATTACK_COMPANY
      user.attack(target, :hack)

    # User dDoS angreifen
    elsif type_id == Action::TYPE_ATTACK_USER_DDOS
      user.attack(target, :ddos)

    # Sperre aufheben
    elsif (type_id == Action::TYPE_SYSTEM_CRASH || type_id == Action::TYPE_DDOS_CRASH )
      true

    # Firmeneinkommen erweitern
    elsif type_id == Action::TYPE_COMPANY_INCOME_EVOLVE
      company = Company.where(id: target_id).first
      target.evolve_income

    # Firmeneinkommen dazukaufen
    elsif type_id == Action::TYPE_COMPANY_INCOME_BUY
      company = Company.where(id: target_id).first
      target.buy_income

    # Firmeneinkommen erweitern
    elsif type_id == Action::TYPE_COMPANY_DEFENSE_EVOLVE
      company = Company.where(id: target_id).first
      target.evolve_defense

    # Firmeneinkommen dazukaufen
    elsif type_id == Action::TYPE_COMPANY_DEFENSE_BUY
      company = Company.where(id: target_id).first
      target.buy_defense

    else
      raise Action::InvalidTypeException.new("Typ '#{type_id.to_s}' ungültig")
    end
    complete!(result)
  end

  def complete!(success = true)
    update_attributes(completed: true, success: success)
  end

  def readable_type
    case type_id
    when Action::TYPE_BOTNET_EVOLVE
      "Increase Botnet"
    when Action::TYPE_BOTNET_BUY
      "Buy Botnet"
    when Action::TYPE_HACKING_EVOLVE
      "Train Hacking Skill"
    when Action::TYPE_HACKING_BUY
      "Buy Hacking Skill"
    when Action::TYPE_DEFENSE_EVOLVE
      "Increase Defense"
    when Action::TYPE_DEFENSE_BUY
      "Buy Defense"
    when Action::TYPE_PERFORM_JOB
      "Performing Job"
    when Action::TYPE_ATTACK_USER
      "Performing Hacking-Attack on #{target.present? ? target.nickname : "another Hacker"}"
    when Action::TYPE_ATTACK_COMPANY
      "Performing Hacking-Attack on #{target.present? ? target.name : "a company"}"
    when Action::TYPE_ATTACK_USER_DDOS
      "Performing dDoS-Attack on #{target.present? ? target.nickname : "another Hacker"}"
    when Action::TYPE_DDOS_CRASH
      "Rebooting System after dDoS-Attack"
    when Action::TYPE_SYSTEM_CRASH
      "Rebooting System"
    when Action::TYPE_COMPANY_INCOME_EVOLVE
      "Increase company income"
    when Action::TYPE_COMPANY_INCOME_BUY
      "Buy company income"
    when Action::TYPE_COMPANY_DEFENSE_EVOLVE
      "Increase company defense"
    when Action::TYPE_COMPANY_DEFENSE_BUY
      "Buy company defense"
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
    def add_for_user(action, user)
      return if user.has_incomplete_actions? && ![Action::TYPE_BOTNET_BUY, Action::TYPE_HACKING_BUY, Action::TYPE_DEFENSE_BUY].include?(action.type_id)
      target_type = nil

      # Validierungen
      will_be_completed_at = if action.type_id == Action::TYPE_BOTNET_EVOLVE
        DateTime.now + user.next_botnet_ratio_time.seconds

      elsif action.type_id == Action::TYPE_BOTNET_BUY
        DateTime.now

      elsif action.type_id == Action::TYPE_DEFENSE_EVOLVE
        DateTime.now + user.next_defense_ratio_time.seconds

      elsif action.type_id == Action::TYPE_DEFENSE_BUY
        DateTime.now

      elsif action.type_id == Action::TYPE_HACKING_EVOLVE
        DateTime.now + user.next_hacking_ratio_time.seconds

      elsif action.type_id == Action::TYPE_HACKING_BUY
        DateTime.now

      elsif action.type_id == Action::TYPE_PERFORM_JOB
        DateTime.now + Job.find(action[:job_id]).duration_for(user).seconds

      elsif action.type_id == Action::TYPE_ATTACK_USER
        target = User.where(id: action.target_id).first
        return if target.blank? || !user.can_attack?(target, :hack)
        target_type = "User"
        DateTime.now + user.time_to_attack(target, :hack).seconds

      elsif action.type_id == Action::TYPE_ATTACK_COMPANY
        target = Company.where(id: action.target_id).first
        return if target.blank? || !user.can_attack?(target, :hack)
        target_type = "Company"
        DateTime.now + user.time_to_attack(target, :hack).seconds

      elsif action.type_id == Action::TYPE_ATTACK_USER_DDOS
        target = User.where(id: action.target_id).first
        return if target.blank? || !user.can_attack?(target, :ddos)
        target_type = "User"
        DateTime.now + user.time_to_attack(target, :ddos).seconds

      elsif action.type_id == Action::TYPE_COMPANY_INCOME_EVOLVE
        target = Company.where(id: action.target_id).first
        return if target.blank? || !target.user_id == user.id
        target_type = "Company"
        DateTime.now + target.next_income_ratio_time.seconds

      elsif action.type_id == Action::TYPE_COMPANY_INCOME_BUY
        target = Company.where(id: action.target_id).first
        return if target.blank? || !user.can_buy_for_company?(Action::TYPE_COMPANY_INCOME_BUY, target)
        target_type = "Company"
        DateTime.now

      elsif action.type_id == Action::TYPE_COMPANY_DEFENSE_EVOLVE
        target = Company.where(id: action.target_id).first
        return if target.blank? || !target.user_id == user.id
        target_type = "Company"
        DateTime.now + target.next_defense_ratio_time.seconds

      elsif action.type_id == Action::TYPE_COMPANY_DEFENSE_BUY
        target = Company.where(id: action.target_id).first
        return if target.blank? || !user.can_buy_for_company?(Action::TYPE_COMPANY_DEFENSE_BUY, target)
        target_type = "Company"
        DateTime.now

      else
        raise Action::InvalidTypeException.new("Typ '#{action.type_id}' ungültig")
      end

      result = Action.create(
        type_id:      action.type_id,
        job_id:       action.job_id,
        user_id:      user.id,
        target_id:    action.target_id,
        target_type:  target_type,
        completed_at: will_be_completed_at,
        completed:    false
      )
      result
    end
  end
end