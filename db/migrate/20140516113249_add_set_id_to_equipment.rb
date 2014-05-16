class AddSetIdToEquipment < ActiveRecord::Migration
  def up
    add_column :equipments, :set_id, :integer
  end

  def down
    remove_column :equipments, :set_id
  end
end