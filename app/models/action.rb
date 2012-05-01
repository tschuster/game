# encoding: utf-8
class Action < ActiveRecord::Base
  belongs_to :user
  belongs_to :job

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

  TYPE_BOTNET_EVOLVE  = 101
  TYPE_BOTNET_BUY     = 102
  TYPE_HACKING_EVOLVE = 103
  TYPE_HACKING_BUY    = 104
  TYPE_DEFENSE_EVOLVE = 105
  TYPE_DEFENSE_BUY    = 106
  TYPE_PERFORM_JOB    = 201

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
    else
      raise Action::InvalidTypeException.new("Typ '#{type_id.to_s}' ungültig")
    end
  end

  def time_remaining
    [completed_at - DateTime.now, 0].max
  end

  class << self

    # eine neue Action für einen User zur Abarbeitung anlegen
    def add_for_user(action, current_user)
      return if current_user.has_incomplete_actions?
      will_be_completed_at = nil

      # Validierungen
      if action[:type_id].to_i == Action::TYPE_BOTNET_EVOLVE
        will_be_completed_at = DateTime.now + current_user.next_botnet_ratio_time.seconds

      elsif action[:type_id].to_i == Action::TYPE_BOTNET_BUY
        will_be_completed_at = DateTime.now

      elsif action[:type_id].to_i == Action::TYPE_DEFENSE_EVOLVE
        will_be_completed_at = DateTime.now + current_user.next_defense_ratio_time.seconds

      elsif action[:type_id].to_i == Action::TYPE_DEFENSE_BUY
        will_be_completed_at = DateTime.now

      elsif action[:type_id].to_i == Action::TYPE_HACKING_EVOLVE
        will_be_completed_at = DateTime.now + current_user.next_hacking_ratio_time.seconds

      elsif action[:type_id].to_i == Action::TYPE_HACKING_BUY
        will_be_completed_at = DateTime.now

      elsif action[:type_id].to_i == Action::TYPE_PERFORM_JOB
        will_be_completed_at = DateTime.now + Job.find(action[:job_id]).duration_for(current_user).seconds

      else
        raise Action::InvalidTypeException.new("Typ '#{type_id.to_s}' ungültig")
      end
      result = Action.create(
        :type_id      => action[:type_id].to_i,
        :job_id       => action[:job_id],
        :user_id      => current_user.id,
        :completed_at => will_be_completed_at,
        :completed    => false
      )
      result
    end
  end
end