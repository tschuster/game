class User < ActiveRecord::Base
  has_many :actions, dependent: :destroy
  has_many :jobs, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :items, dependent: :destroy
  has_many :companies
  has_many :clusters

  validates :nickname, exclusion: { in: ["admin", "administrator"], message: "is not allowed" }, uniqueness: { case_sensitive: false, message: "is already taken" }, presence: { message: "is required" }

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :nickname, :email, :password, :password_confirmation, :remember_me, :money, :botnet_ratio, :hacking_ratio, :defense_ratio, :notify

  before_destroy :clear_company

  def hacking_ratio
    super + items.active.map(&:hacking_bonus).sum
  end

  def hacking_ratio_without_bonus
    hacking_ratio - items.active.map(&:hacking_bonus).sum
  end

  def botnet_ratio
    super + items.active.map(&:botnet_bonus).sum
  end

  def botnet_ratio_without_bonus
    botnet_ratio - items.active.map(&:botnet_bonus).sum
  end

  def defense_ratio
    super + items.active.map(&:defense_bonus).sum
  end

  def defense_ratio_without_bonus
    defense_ratio - items.active.map(&:defense_bonus).sum
  end

  # stoppt alle aktuellen Actions
  def cancel_actions!
    actions.incomplete.update_all(completed: true)
  end

  # eigenes Botnet erweitern
  def evolve_botnet
    update_attribute(:botnet_ratio, botnet_ratio_without_bonus + CONFIG["botnet"]["evolve_ratio"].to_i)
  end

  # Botnet-Erweiterung dazukaufen
  def buy_botnet
    return false if money < next_botnet_ratio_cost
    update_attributes(money: [0, (money-next_botnet_ratio_cost)].max, botnet_ratio: botnet_ratio_without_bonus + CONFIG["botnet"]["buy_ratio"].to_i)
  end

  # eigene Hacking-Skills erweitern
  def evolve_hacking
    update_attribute(:hacking_ratio, hacking_ratio_without_bonus + CONFIG["hacking"]["evolve_ratio"].to_i)
  end

  # Hacking-Skill dazukaufen
  def buy_hacking
    return false if money < next_hacking_ratio_cost
    update_attributes(money: [0, (money-next_hacking_ratio_cost)].max, hacking_ratio: hacking_ratio_without_bonus + CONFIG["hacking"]["buy_ratio"].to_i)
  end

  # eigene Verteidigung erweitern
  def evolve_defense
    update_attribute(:defense_ratio, defense_ratio_without_bonus + CONFIG["defense"]["evolve_ratio"].to_i)
  end

  # Hacking-Skill dazukaufen
  def buy_defense
    return false if money < next_defense_ratio_cost
    update_attributes(money: [0, (money-next_defense_ratio_cost)].max, defense_ratio: defense_ratio_without_bonus + CONFIG["defense"]["buy_ratio"].to_i)
  end

  def has_purchased?(equipment)
    items.pluck(:equipment_id).include?(equipment.id)
  end

  def can_purchase?(equipment)
    money >= equipment.price
  end

  def can_buy?(action_id)
    case action_id
    when Action::TYPE_HACKING_BUY
      money >= next_hacking_ratio_cost
    when Action::TYPE_BOTNET_BUY
      money >= next_botnet_ratio_cost
    when Action::TYPE_DEFENSE_BUY
      money >= next_defense_ratio_cost
    end
  end

  def can_buy_for_company?(action_id, company)
    return false if company.user_id != id
    case action_id
    when Action::TYPE_COMPANY_INCOME_BUY
      money >= company.next_income_ratio_cost
    when Action::TYPE_COMPANY_DEFENSE_BUY
      money >= company.next_defense_ratio_cost
    end
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
    return false if target.blank?
    success = false
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
          stolen_money /= 2 if target.wallet_active?
          receive_money!(stolen_money) if stolen_money > 0.0

          # Notifications
          Notification.create_for(:attack_success_victim, target, value: stolen_money, attacker: self)
          Notification.create_for(:attack_success_attacker, self, value: stolen_money, victim: target)
        elsif type == :ddos

          # Actions hart canceln
          target.cancel_actions!
          Action.create(
            type_id:      Action::TYPE_DDOS_CRASH,
            user_id:      target.id,
            completed_at: DateTime.now + 60.minutes,
            completed:    false
          )

          # Notifications
          Notification.create_for(:ddos_success_victim, target, attacker: self)
          Notification.create_for(:ddos_success_attacker, self, victim: target)
        end
      else

        # attack failed, create notifications
        if type == :hack
          Action.create(
            type_id:      Action::TYPE_SYSTEM_CRASH,
            user_id:      id,
            completed_at: DateTime.now + (bootloader_active? ? 15.minutes : 60.minutes),
            completed:    false
          )

          Notification.create_for(:attack_failed_victim, target, attacker: self)
          Notification.create_for(:attack_failed_attacker, self, victim: target)
        elsif type == :ddos
          Notification.create_for(:ddos_failed_victim, target, attacker: self)
          Notification.create_for(:ddos_failed_attacker, self, victim: target)
        end
      end
      Notification.create_for_all!(:attack, attacker: self, victim: target, skip: [target.id, self.id])
    else
      result = rand(hacking_ratio + target.defense_ratio)
      success = result <= hacking_ratio

      if success

        # Angriff erfolgreich
        Notification.create_for(:attack_company_success_previous_owner, target.user, victim: target, attacker: self) if target.user.present?
        target.get_controlled_by!(self)

        # Notifications
        Notification.create_for(:attack_company_success_attacker, self, victim: target, value: target.income_per_hour)
      else

        # attack failed
        Action.create(
          type_id:      Action::TYPE_SYSTEM_CRASH,
          user_id:      id,
          completed_at: DateTime.now + 60.minutes,
          completed:    false
        )

        # Notification
        Notification.create_for(:attack_company_failed_attacker, self, victim: target)
        Notification.create_for(:attack_company_failed_owner, target.user, victim: target, attacker: self) if target.user.present?
      end
      Notification.create_for_all!(:attack_company, attacker: self, victim: target, success: success, skip: [self.id])
    end
    success
  end

  def next_botnet_ratio_time
    botnet_ratio_without_bonus * botnet_ratio_without_bonus / 4
  end

  def next_botnet_ratio_cost
    botnet_ratio_without_bonus.to_f
  end

  def next_defense_ratio_time
    defense_ratio_without_bonus * defense_ratio_without_bonus / 4
  end

  def next_defense_ratio_cost
    defense_ratio_without_bonus.to_f
  end

  def next_hacking_ratio_time
    hacking_ratio_without_bonus * hacking_ratio_without_bonus / 4
  end

  def next_hacking_ratio_cost
    hacking_ratio_without_bonus.to_f
  end

  def time_to_attack(target, type = :hack)
    return unless can_attack?(target, type)
    if type == :ddos
      300/chance_of_success_against(target, type)*100
    else
      600/chance_of_success_against(target, type)*100
    end
  end

  def can_attack?(target, type = :hack)
    return false if to_strong_for(target, type) || to_weak_for(target, type)
    if target.is_a?(User)
      return false if target.id == id
      chance_of_success_against(target, type) > 0
    else
      return false if controls?(target)
      chance_of_success_against(target, type) > 0
    end
  end

  def controls?(company)
    company.user_id == id
  end

  def has_incomplete_actions?
    actions.incomplete.present?
  end

  def current_job
    Job.where(user_id: id, completed: false).first
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
      if target.is_a?(Company)
        target.defense_ratio < hacking_ratio * 0.1
      else
        (target.defense_ratio + target.botnet_ratio + target.hacking_ratio)/3.0 < hacking_ratio * 0.1
      end
    when :ddos
      if target.is_a?(Company)
        target.defense_ratio < botnet_ratio * 0.1
      else
        (target.defense_ratio + target.botnet_ratio + target.hacking_ratio)/3.0 < botnet_ratio * 0.1
      end
    end
  end

  def to_weak_for(target, type = :hack)
    case type
    when :hack
      target.defense_ratio > hacking_ratio * 2.5
    when :ddos
      target.defense_ratio > botnet_ratio * 2.5
    end
  end

  def chance_of_success_against(target, type = :hack)

    # Gegner zu stark? oder zu schwach?
    return 0 if to_strong_for(target, type) || to_weak_for(target, type)

    if type == :hack
      return 0 if hacking_ratio + target.defense_ratio == 0
      return 0 if target.is_a?(Company) && controls?(target)

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

  def clear_company
    company.update_attribute(:user_id, nil) if company.present?
  end

  def notify?
    notify
  end

  def intruder_alert!
    return if email.blank? || !notify? || !intrusion_detection_active?
    Notifier.intruder_alert(self).deliver
  end

  def intrusion_detection_active?
    intrusion_detection_system = Equipment.where(klass: :utility, special_bonus: "ids").first
    items.where(equipment_id: intrusion_detection_system.id, equipped: true).first.present?
  end

  def bootloader_active?
    Equipment.where(klass: :utility, special_bonus: "boot").first.equipped_by?(self)
  end

  def wallet_active?
    Equipment.where(klass: :utility, special_bonus: "wallet").first.equipped_by?(self)
  end

  def has_complete_set?(set_id)
    set_equipments = Equipment.where(set_id: set_id).pluck(:id)
    return false if set_equipments.blank?
    items.active.pluck(:equipment_id) & set_equipments == set_equipments
  end

  def total_income_per_hour
    return nil if companies.blank?
    companies.map(&:income_per_hour).sum
  end

  class << self
    def average_botnet_ratio
      User.pluck(:botnet_ratio).sum/User.count
    end

    def best_botnet_ratio
      User.order("botnet_ratio DESC").first.botnet_ratio
    end

    def average_hacking_ratio
      User.pluck(:hacking_ratio).sum/User.count
    end

    def best_hacking_ratio
      User.order("hacking_ratio DESC").first.hacking_ratio
    end
  end

  protected

    def email_required?
      false 
    end
end