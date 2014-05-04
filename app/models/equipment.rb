class Equipment < ActiveRecord::Base
  set_table_name "equipments"
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

  def computed_hacking_bonus
    hacking_bonus.to_i + case special_bonus
    when :special_1
      0
    else
      0
    end
  end

  def computed_botnet_bonus
    botnet_bonus.to_i + case special_bonus
    when :special_1
      0
    else
      0
    end
  end

  def computed_defense_bonus
    defense_bonus.to_i + case special_bonus
    when :special_1
      0
    else
      0
    end
  end
end