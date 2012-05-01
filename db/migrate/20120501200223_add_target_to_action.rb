class AddTargetToAction < ActiveRecord::Migration
  def up
    change_table :actions do |t|
      t.integer :target_id, :default => nil
      t.string :target_type
    end
  end

  def down
    change_table :actions do |t|
      t.remove :target_id
      t.remove :target_type
    end 
  end
end