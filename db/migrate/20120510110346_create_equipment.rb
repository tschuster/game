class CreateEquipment < ActiveRecord::Migration
  def change
    create_table :equipment do |t|
      t.integer :user_id
      t.string  :klass
      t.string  :item_id
      t.string  :title
      t.integer :hacking_bonus, default: 0
      t.integer :botnet_bonus, default: 0
      t.integer :defense_bonus, default: 0
      t.integer :price, default: 0
      t.boolean :active, default: false

      t.timestamps
    end
  end
end