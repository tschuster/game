class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.integer :user_id
      t.integer :equipment_id
      t.boolean :equipped, default: false

      t.timestamps
    end
  end
end