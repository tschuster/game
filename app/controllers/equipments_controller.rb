# encoding: utf-8
class EquipmentsController < ApplicationController
  before_filter :set_equipment_by_item_id, :only => [:buy]
  before_filter :set_equipment, :only => [:update]
  before_filter :set_equipments, :only => [:index]
  before_filter :set_available_equipments, :only => [:index]

  def index
  end

  def update
    if !current_user.has_purchased? @equipment
      flash.alert = "You do not own this equipment!"
    elsif params[:unequip].present? && @equipment.unequip!
      
    elsif @equipment.equip!
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
      @equipment = Equipment.where(:id => params[:id]).first
    end

    def set_equipment_by_item_id
      @equipment = Equipment.build_by_item_id(params[:item_id])
    end

    def set_equipments
      @equipments = current_user.equipments.sort_by! { |elm| elm.item_id.split("_") }
    end

    def set_available_equipments
      @available_equipments = []
      EQUIPMENT.each_pair do |key_prefix, eqmts|
        eqmts.each_pair do |key_suffix, eqmt|
          @available_equipments << Equipment.new(
            title: eqmt["title"],
            item_id: [key_prefix, key_suffix].join("_"),
            klass: eqmt["klass"],
            hacking_bonus: eqmt["hacking_bonus"].to_i,
            botnet_bonus: eqmt["botnet_bonus"].to_i,
            defense_bonus: eqmt["defense_bonus"].to_i,
            price: eqmt["price"].to_i
          )
        end
      end
      @available_equipments.sort_by! { |elm| elm.item_id.split("_") }
    end
end