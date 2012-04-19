class User < ActiveRecord::Base
  has_many :actions
  has_many :jobs

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :money, :botnet_ratio, :hacking_ratio

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

  def next_botnet_ratio_time
    botnet_ratio * botnet_ratio / 4
  end

  def next_hacking_ratio_time
    hacking_ratio * hacking_ratio / 4
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
end