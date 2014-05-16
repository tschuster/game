class Equipment < ActiveRecord::Base
  self.table_name = "equipments"
  has_many :items

  symbolize :klass, in: [ :firewall, :compiler, :botnet, :utility ], scope: true

  attr_accessible :title, :description, :hacking_bonus, :botnet_bonus, :defense_bonus, :special_bonus, :price

  class ImplementationMissingException < StandardError
  end

  def readable_class
    case klass
    when :firewall
      "Firewall"
    when :compiler
      "Compiler"
    when :botnet
      "Botnet"
    when :utility
      "Utility"
    else
      raise Equipment::ImplementationMissingException.new("Typ '#{klass}' ungültig")
    end
  end

  def equipped_by?(user)
    user.items.where(equipment_id: id, equipped: true).first.present?
  end

  def purchased_by?(user)
    user.items.where(equipment_id: id).first.present?
  end

  def purchase_and_equip_by!(user)
    return if equipped_by?(user) || purchased_by?(user)

    new_item = Item.new(user_id: user.id, equipment_id: id, equipped: true)
    new_item.save!
  end

  def set?
    set_id.present?
  end
  def computed_hacking_bonus_for(user)
    hacking_bonus.to_i + case special_bonus
    when "set_netmaster"
      if hacking_bonus.present? && user.present? && user.has_complete_set?(set_id)
      (hacking_bonus*0.1).to_i
      else
        0
      end
    when "set_team13"
      (hacking_bonus.present? && user.present? && user.has_complete_set?(set_id)) ? 15 : 0
    else
      0
    end
  end

  def computed_botnet_bonus_for(user)
    botnet_bonus.to_i + case special_bonus
    when "set_netmaster"
      if botnet_bonus.present? && user.present? && user.has_complete_set?(set_id)
      (botnet_bonus*0.1).to_i
      else
        0
      end
    else
      0
    end
  end

  def computed_defense_bonus_for(user)
    defense_bonus.to_i + case special_bonus
    when "set_netmaster"
      if defense_bonus.present? && user.present? && user.has_complete_set?(set_id)
      (defense_bonus*0.1).to_i
      else
        0
      end
    when "set_team13"
      (defense_bonus.present? && user.present? && user.has_complete_set?(set_id)) ? 15 : 0
    else
      0
    end
  end
end