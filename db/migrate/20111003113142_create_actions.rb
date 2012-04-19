class CreateActions < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.integer :type_id
      t.integer :user_id
      t.integer :job_id
      t.timestamps
      t.datetime :completed_at
      t.boolean :completed, :default => false
    end
  end
end
