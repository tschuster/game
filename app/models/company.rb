class Company < ActiveRecord::Base
  belongs_to :user

  def get_controlled_by!(user)
    reload
    user_id = user.id
    update_attribute(:defense_ratio, [(user.hacking_ratio*1.2).to_i, (self.defense_ratio*1.2).to_i].max)
    save
  end

  def defend_against(user)
    update_attribute(:defense_ratio, [(user.hacking_ratio*1.2).to_i, (self.defense_ratio*1.2).to_i].max)
  end

  def money_per_action
    worth.to_f/72
  end

  def money_per_hour
    money_per_action*360
  end

  # Wert ausbezahlen
  def payout!
    return if user.blank?
    user.receive_money!(money_per_action)
  end
end