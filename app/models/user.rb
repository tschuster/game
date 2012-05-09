class User < ActiveRecord::Base
  has_many :actions
  has_many :jobs
  has_many :notifications

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

  # eigenes Botnet erweitern
  def evolve_botnet
    update_attribute(:botnet_ratio, botnet_ratio + CONFIG["botnet"]["evolve_ratio"].to_i)
  end

  # Botnet-Erweiterung dazukaufen
  def buy_botnet
    return if money < CONFIG["botnet"]["buy_cost"].to_i
    update_attributes(:money => [0, (money-CONFIG["botnet"]["buy_cost"].to_i)].max, :botnet_ratio => botnet_ratio + CONFIG["botnet"]["buy_ratio"].to_i)
  end

  # eigene Hacking-Skills erweitern
  def evolve_hacking
    update_attribute(:hacking_ratio, hacking_ratio + CONFIG["hacking"]["evolve_ratio"].to_i)
  end

  # Hacking-Skill dazukaufen
  def buy_hacking
    return if money < CONFIG["hacking"]["buy_cost"].to_i
    update_attributes(:money => [0, (money-CONFIG["hacking"]["buy_cost"].to_i)].max, :hacking_ratio => hacking_ratio + CONFIG["hacking"]["buy_ratio"].to_i)
  end

  # eigene Verteidigung erweitern
  def evolve_defense
    update_attribute(:defense_ratio, defense_ratio + CONFIG["defense"]["evolve_ratio"].to_i)
  end

  # Hacking-Skill dazukaufen
  def buy_defense
    return if money < CONFIG["defense"]["buy_cost"].to_i
    update_attributes(:money => [0, (money-CONFIG["defense"]["buy_cost"].to_i)].max, :defense_ratio => defense_ratio + CONFIG["defense"]["buy_ratio"].to_i)
  end

  def attack(target)
    return if target.blank?
    if target.is_a?(User)
      
      result = rand(hacking_ratio + target.defense_ratio)
      if result <= hacking_ratio

        # attack succesfull
        stolen_money = target.take_money!((400/chance_of_success_against(target).to_f*100).round)
        receive_money!(stolen_money) if stolen_money > 0.0

        # Notifications
        Notification.create_for(:attack_success_victim, target, :value => stolen_money, :attacker => self)
        Notification.create_for(:attack_success_attacker, self, :value => stolen_money, :victim => target)
      else

        # attack failed
        Action.create(
          :type_id      => Action::TYPE_SYSTEM_CRASH,
          :user_id      => id,
          :completed_at => DateTime.now + 60.minutes,
          :completed    => false
        )

        # Notifications
        Notification.create_for(:attack_failed_victim, target, :attacker => self)
        Notification.create_for(:attack_failed_attacker, self, :victim => target)
      end
      Notification.create_for_all!(:attack, :attacker => self, :victim => target)
    else
      # TODO: implement!
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

  def time_to_attack(user)
    return if chance_of_success_against(user) <= 0
    600/chance_of_success_against(user)*100
  end

  def has_incomplete_actions?
    actions.incomplete.present?
  end

  def current_job
    Job.where(:user_id => id, :completed => false).first
  end

  def receive_money!(value)
    update_attribute(:money, money+value)
  end

  def take_money!(value)
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

  def chance_of_success_against(user)

    # Gegner zu stark?
    return 0 if user.defense_ratio > hacking_ratio * 1.5 || hacking_ratio + user.defense_ratio == 0

    # Summe aller Werte bildet die Anteile des Angreifers und Verteidigers ab
    (hacking_ratio.to_f / (hacking_ratio + user.defense_ratio).to_f * 100).to_i
  end

  def unread_notifications_count
    notifications.unread.count
  end
end