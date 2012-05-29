class AddRequirementsToJobs < ActiveRecord::Migration
  def change
    change_table :jobs do |t|
      t.integer :complexity, :default => 1
      t.integer :hacking_ratio_required, :default => 0
      t.integer :botnet_ratio_required, :default => 0
    end
  end
end