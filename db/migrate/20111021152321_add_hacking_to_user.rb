class AddHackingToUser < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.integer :hacking_ratio, :default => 10
    end
  end
end
