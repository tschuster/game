class Equipments < ActiveRecord::Migration
  def up
    create_table :equipments do |t|
      t.string :klass
      t.integer :level
      t.string :title
      t.text :description
      t.integer :hacking_bonus
      t.integer :botnet_bonus
      t.integer :defense_bonus
      t.string :special_bonus
      t.float :price
    end
    drop_table :equipment
  end

  def down
    create_table :equipment do |t|
      t.integer :user_id
      t.string  :klass
      t.string  :item_id
      t.string  :title
      t.integer :hacking_bonus, :default => 0
      t.integer :botnet_bonus, :default => 0
      t.integer :defense_bonus, :default => 0
      t.integer :price, :default => 0
      t.boolean :active, :default => false

      t.timestamps
    end

    drop_table :equipments
  end
end