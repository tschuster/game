class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :user_id
      t.integer :from_user_id
      t.string :klass
      t.text :message
      t.boolean :is_new, default: true

      t.timestamps
    end
  end
end