# encoding: utf-8
class EquipmentsController < ApplicationController
  before_filter :set_equipment, only: [:buy]
  before_filter :set_item, only: [:update]
  before_filter :set_equipments, only: [:index]
  before_filter :set_available_equipments, only: [:index]

  def index
  end

  def update
    if !current_user.has_purchased? @item.equipment
      flash.alert = "You do not own this equipment!"
    elsif params[:unequip].present? && @item.unequip!
      
    elsif @item.equip!
      flash.notice = "Item equipped"
    else
      flash.alert = "Something went wrong..."
    end
    redirect_to equipments_path
  end

  def buy
    if @equipment.present?
      if current_user.has_purchased? @equipment
        flash.alert = "You have already purchased this!"
      elsif !current_user.can_purchase? @equipment
        flash.alert = "You cannot purchase this!"

      # Kauf!
      elsif current_user.purchase! @equipment
        flash.notice = "Thanks and come again!"
      else
        flash.alert = "Something went wrong..."
      end
    else
      flash.alert = "Equipment not available"
    end
    redirect_to equipments_path
  end

  protected

    def set_equipment
      @equipment = Equipment.where(id: params[:item_id]).first
    end

    def set_item
      @equipment = Equipment.where(id: params[:id]).first
      @item = current_user.items.where(equipment_id: @equipment.id).first
    end

    def set_equipments
      @user_firewalls = Equipment.where("id in(?)", current_user.items.pluck(:equipment_id)).where(klass: :firewall).order(:level)
      @user_compilers = Equipment.where("id in(?)", current_user.items.pluck(:equipment_id)).where(klass: :compiler).order(:level)
      @user_botnets = Equipment.where("id in(?)", current_user.items.pluck(:equipment_id)).where(klass: :botnet).order(:level)
      @user_utilities = Equipment.where("id in(?)", current_user.items.pluck(:equipment_id)).where(klass: :utility).order(:level)
    end

    def set_available_equipments
      @available_firewalls = Equipment.where(klass: :firewall).order(:level)
      @available_compilers = Equipment.where(klass: :compiler).order(:level)
      @available_botnets = Equipment.where(klass: :botnet).order(:level)
      @available_utilities = Equipment.where(klass: :utility).order(:level)
      @available_equipments = Equipment.order(:klass)
    end
end