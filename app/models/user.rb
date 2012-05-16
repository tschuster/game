class User < ActiveRecord::Base
  has_many :actions
  has_many :jobs
  has_many :notifications
  has_many :equipments
  has_many :companies

  validates :nickname, :exclusion => { :in => ["admin", "administrator"] }, :uniqueness => { :case_sensitive => false}, :presence => true

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :nickname, :email, :password, :password_confirmation, :remember_me, :money, :botnet_ratio, :hacking_ratio, :defense_ratio

  # führt die gewählte Aktion des Users aus
  def perform_next_action!
    action = Action.find(:first, :conditions => {:completed => false})
    action.perform! if action.present?
  end

  def hacking_ratio
    super + equipments.active.pluck(:hacking_bonus).sum
  end

  def hacking_ratio_without_bonus
    hacking_ratio - equipments.active.pluck(:hacking_bonus).sum
  end

  def botnet_ratio
    super + equipments.active.pluck(:botnet_bonus).sum
  end

  def botnet_ratio_without_bonus
    botnet_ratio - equipments.active.pluck(:botnet_bonus).sum
  end

  def defense_ratio
    super + equipments.active.pluck(:defense_bonus).sum
  end

  def defense_ratio_without_bonus
    defense_ratio - equipments.active.pluck(:defense_bonus).sum
  end

  # stoppt alle aktuellen Actions
  def cancel_actions!
    actions.incomplete.update_all(:completed => true)
  end

  # eigenes Botnet erweitern
  def evolve_botnet
    update_attribute(:botnet_ratio, botnet_ratio_without_bonus + CONFIG["botnet"]["evolve_ratio"].to_i)
  end

  # Botnet-Erweiterung dazukaufen
  def buy_botnet
    return if money < CONFIG["botnet"]["buy_cost"].to_i
    update_attributes(:money => [0, (money-CONFIG["botnet"]["buy_cost"].to_i)].max, :botnet_ratio => botnet_ratio_without_bonus + CONFIG["botnet"]["buy_ratio"].to_i)
  end

  # eigene Hacking-Skills erweitern
  def evolve_hacking
    update_attribute(:hacking_ratio, hacking_ratio_without_bonus + CONFIG["hacking"]["evolve_ratio"].to_i)
  end

  # Hacking-Skill dazukaufen
  def buy_hacking
    return if money < CONFIG["hacking"]["buy_cost"].to_i
    update_attributes(:money => [0, (money-CONFIG["hacking"]["buy_cost"].to_i)].max, :hacking_ratio => hacking_ratio_without_bonus + CONFIG["hacking"]["buy_ratio"].to_i)
  end

  # eigene Verteidigung erweitern
  def evolve_defense
    update_attribute(:defense_ratio, defense_ratio_without_bonus + CONFIG["defense"]["evolve_ratio"].to_i)
  end

  # Hacking-Skill dazukaufen
  def buy_defense
    return if money < CONFIG["defense"]["buy_cost"].to_i
    update_attributes(:money => [0, (money-CONFIG["defense"]["buy_cost"].to_i)].max, :defense_ratio => defense_ratio_without_bonus + CONFIG["defense"]["buy_ratio"].to_i)
  end

  def has_purchased?(equipment)
    equipments.pluck(:item_id).include?(equipment.item_id)
  end

  def can_purchase?(equipment)
    money >= equipment.price
  end

  def purchase!(equipment)
    return unless can_purchase?(equipment)
    return if has_purchased?(equipment)

    User.transaction do
      begin
        take_money!(equipment.price)
        equipment.purchase_and_equip_by!(self)
      rescue Exception => e
        Rails.logger.info(e.message)
        raise ActiveRecord::Rollback
      end
    end
  end

  def attack(target, type = :hack)
    return if target.blank?
    if target.is_a?(User)

      if type == :hack
        result = rand(hacking_ratio + target.defense_ratio)
        success = result <= hacking_ratio
      elsif type == :ddos
        result = rand(botnet_ratio + target.defense_ratio)
        success = result <= botnet_ratio
      end
      if success

        # Angriff erfolgreich
        if type == :hack
          stolen_money = target.take_money!((400/chance_of_success_against(target, :hack).to_f*100).round)
          receive_money!(stolen_money) if stolen_money > 0.0

          # Notifications
          Notification.create_for(:attack_success_victim, target, :value => stolen_money, :attacker => self)
          Notification.create_for(:attack_success_attacker, self, :value => stolen_money, :victim => target)
        elsif type == :ddos

          # Actions hart canceln
          target.cancel_actions!
          Action.create(
            :type_id      => Action::TYPE_DDOS_CRASH,
            :user_id      => target.id,
            :completed_at => DateTime.now + 60.minutes,
            :completed    => false
          )

          # Notifications
          Notification.create_for(:ddos_success_victim, target, :attacker => self)
          Notification.create_for(:ddos_success_attacker, self, :victim => target)
        end
      else

        # attack failed
        Action.create(
          :type_id      => Action::TYPE_SYSTEM_CRASH,
          :user_id      => id,
          :completed_at => DateTime.now + 60.minutes,
          :completed    => false
        )

        # Notifications
        if type == :hack
          Notification.create_for(:attack_failed_victim, target, :attacker => self)
          Notification.create_for(:attack_failed_attacker, self, :victim => target)
        elsif type == :ddos
          Notification.create_for(:ddos_failed_victim, target, :attacker => self)
          Notification.create_for(:ddos_failed_attacker, self, :victim => target)
        end
      end
      Notification.create_for_all!(:attack, :attacker => self, :victim => target)
    else
      result = rand(hacking_ratio + target.defense_ratio)
      success = result <= hacking_ratio

      if success

        # Angriff erfolgreich
        Notification.create_for(:attack_company_success_previous_owner, target.user, :victim => target, :attacker => self) if target.user.present?
        target.get_controlled_by!(self)

        # Notifications
        Notification.create_for(:attack_company_success_attacker, self, :victim => target, :value => target.money_per_hour)
      else

        # attack failed
        target.defend_against(self)
        Action.create(
          :type_id      => Action::TYPE_SYSTEM_CRASH,
          :user_id      => id,
          :completed_at => DateTime.now + 60.minutes,
          :completed    => false
        )

        # Notification
        Notification.create_for(:attack_company_failed_attacker, self, :victim => target)
        Notification.create_for(:attack_company_failed_owner, target.user, :victim => target, :attacker => self) if target.user.present?
      end
      Notification.create_for_all!(:attack_company, :attacker => self, :victim => target, :success => success)
    end
  end

  def next_botnet_ratio_time
    botnet_ratio * botnet_ratio / 4
  end

  def next_defense_ratio_time
    defense_ratio * defense_ratio / 4
  end

  def next_hacking_ratio_time
    hacking_ratio * hacking_ratio / 4
  end

  def time_to_attack(target, type = :hack)
    return unless can_attack?(target, type)
    600/chance_of_success_against(target, type)*100
  end

  def can_attack?(target, type = :hack)
    return false if to_strong_for(target, type) || to_weak_for(target, type)
    if target.is_a?(User)
      chance_of_success_against(target, type) > 0
    else
      !controls?(target) || chance_of_success_against(target, type) > 0
    end
  end

  def controls?(company)
    company.user_id == id
  end

  def has_incomplete_actions?
    actions.incomplete.present?
  end

  def current_job
    Job.where(:user_id => id, :completed => false).first
  end

  def receive_money!(value)
    reload
    update_attribute(:money, money+value)
  end

  def take_money!(value)
    reload
    if value >= money
      result_money = money
      update_attribute(:money, 0)
      result_money
    else
      update_attribute(:money, money-value)
      value
    end
  end

  def admin?
    id == 1
  end

  def to_strong_for(target, type = :hack)
    case type
    when :hack
      target.defense_ratio < hacking_ratio * 0.3
    when :ddos
      target.defense_ratio < botnet_ratio * 0.3
    end
  end

  def to_weak_for(target, type = :hack)
    case type
    when :hack
      target.defense_ratio > hacking_ratio * 1.5
    when :ddos
      target.defense_ratio > botnet_ratio * 1.5
    end
  end

  def chance_of_success_against(target, type = :hack)

    # Gegner zu stark? oder zu schwach?
    return 0 if to_strong_for(target, type)
    return 0 if to_weak_for(target, type)

    if type == :hack
      return 0 if hacking_ratio + target.defense_ratio == 0

      # Summe aller Werte bildet die Anteile des Angreifers und Verteidigers ab
      (hacking_ratio.to_f / (hacking_ratio + target.defense_ratio).to_f * 100).to_i

    elsif type == :ddos
      return if botnet_ratio + target.defense_ratio == 0

      # Summe aller Werte bildet die Anteile des Angreifers und Verteidigers ab
      (botnet_ratio.to_f / (botnet_ratio + target.defense_ratio).to_f * 100).to_i
    end
  end

  def unread_notifications_count
    notifications.unread.count
  end
end