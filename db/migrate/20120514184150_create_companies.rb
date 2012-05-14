class CreateCompanies < ActiveRecord::Migration
  def up
    create_table :companies do |t|
      t.string :name
      t.integer :user_id
      t.integer :defense_ratio
      t.integer :worth

      t.timestamps
    end

    change_column :users, :money, :decimal, :precision => 10, :scale => 2, :default => 100
  end

  def down
    drop_table :companies
    change_column :users, :money, :integer, :default => 100
  end
end