# encoding: utf-8
class Equipment < ActiveRecord::Base
  belongs_to :user

  symbolize :klass, :in => [ :firewall, :compiler, :botnet ], :scope => true

  scope :active, where(:active => true)

  before_save :deactivate_same_klass

  class ImplementationMissingException < StandardError
  end

  class << self
    def build_by_item_id(item_id)
      return if item_id.blank?
      begin
        Equipment.new((EQUIPMENT[item_id.split("_").first][item_id.split("_").last.to_i]).merge({:item_id => item_id}))
      rescue
      end
    end
  end

  def readable_class
    case klass
    when :firewall
      "Firewall"
    when :compiler
      "Compiler"
    when :botnet
      "Botnet"
    else
      raise Equipment::ImplementationMissingException.new("Typ '#{klass}' ungültig")
    end
  end

  def equipped?
    active
  end

  def equipped_by?(user)
    equipped? && user_id == user.id
  end

  def purchased?
    persisted? && user_id.present?
  end

  def equip!
    return unless persisted?

    update_attribute(:active, true)
  end

  def unequip!
    return unless persisted?

    update_attribute(:active, false)
  end

  def purchase_and_equip_by!(user)
    return if persisted?

    self.user = user
    self.active = true
    save!
  end

  # andere des gleichen Typs deaktivieren
  def deactivate_same_klass
    Equipment.where(self.id.present? ? (["id != ?", self.id]) : "1=1").where(:user_id => user_id, :klass => self.klass).update_all(:active => false)
  end
end