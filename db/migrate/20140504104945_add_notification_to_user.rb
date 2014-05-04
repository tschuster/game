class AddNotificationToUser < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.boolean :notify, default: false
    end
  end

  def down
    remove_column :users, :notify
  end
end