class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :title
      t.text :description
      t.integer :type_id
      t.integer :difficulty
      t.integer :target_id
      t.integer :reward
      t.integer :user_id
      t.timestamps
      t.datetime :completed_at
      t.boolean :completed, :default => false
      t.boolean :success
    end
  end
end