class Company < ActiveRecord::Base
  belongs_to :user

  def get_controlled_by!(user)
    reload
    update_attributes(user_id: user.id, defense_ratio: [(user.hacking_ratio*1.2).to_i, (self.defense_ratio*1.2).to_i].max)
  end

  def defend_against(user)
    update_attribute(:defense_ratio, [(user.hacking_ratio*1.2).to_i, (self.defense_ratio*1.2).to_i].max)
  end

  def income_per_action
    income/6.0/60.0
  end

  def income_per_hour
    income
  end

  def income
    worth
  end

  # Wert ausbezahlen
  def payout!
    return if user.blank?
    user.receive_money!(income_per_action)
  end

  def next_income_ratio_time
    income * income*100 / 4
  end

  def next_income_ratio_cost
    income * 100.0
  end

  def next_defense_ratio_time
    defense_ratio * defense_ratio / 4
  end

  def next_defense_ratio_cost
    defense_ratio.to_f
  end

  # Einkommen erhöhen
  def evolve_income
    update_attribute(:worth, income + CONFIG["company"]["income_evolve_ratio"].to_f)
  end

  # Einkommen dazukaufen
  def buy_income
    return false if user.blank? || user.money < next_income_ratio_cost
    user.take_money!(next_income_ratio_cost)
    update_attributes(worth: income + CONFIG["company"]["income_evolve_ratio"].to_f)
  end

  # Verteidigung erhöhen
  def evolve_defense
    update_attribute(:defense_ratio, defense_ratio + CONFIG["company"]["defense_evolve_ratio"].to_i)
  end

  # Verteidigung dazukaufen
  def buy_defense
    return false if user.blank? || user.money < next_defense_ratio_cost
    user.take_money!(next_defense_ratio_cost)
    update_attributes(worth: defense_ratio + CONFIG["company"]["defense_evolve_ratio"].to_i)
  end
end