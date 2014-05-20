class AddSuccessToAction < ActiveRecord::Migration
  def up
    add_column :actions, :success, :boolean, default: false
  end

  def down
    remove_column :actions, :success
  end
end