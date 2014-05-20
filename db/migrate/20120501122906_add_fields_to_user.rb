class AddFieldsToUser < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.string :nickname
      t.integer :defense_ratio, default: 10
    end
  end

  def down
    change_table :users do |t|
      t.remove :nickname
      t.remove :defense_ratio
    end
  end
end