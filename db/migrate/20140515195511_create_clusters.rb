class CreateClusters < ActiveRecord::Migration
  def change
    create_table :clusters do |t|
      t.string :map_id
      t.string :name
      t.integer :user_id
    end
  end
end