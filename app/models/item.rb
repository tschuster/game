class Item < ActiveRecord::Base
  belongs_to :user
  belongs_to :equipment

  attr_accessible :equipment_id, :equipped, :user_id

  scope :active, where(equipped: true)

  before_save :deactivate_same_klass

  # andere des gleichen Typs deaktivieren
  def deactivate_same_klass
   user.items.where("equipment_id in (?)", Equipment.where(klass: equipment.klass).where(id != equipment.id).map(&:id)).update_all(equipped: false)
  end

  def equip!
    update_attribute(:equipped, true)
  end

  def unequip!
    update_attribute(:equipped, false)
  end

  def purchased?
    persisted? && user_id.present?
  end

  def hacking_bonus
    equipment.computed_hacking_bonus
  end

  def botnet_bonus
    equipment.computed_botnet_bonus
  end

  def defense_bonus
    equipment.computed_defense_bonus
  end
end