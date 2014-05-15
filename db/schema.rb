# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140515195511) do

  create_table "actions", :force => true do |t|
    t.integer  "type_id"
    t.integer  "user_id"
    t.integer  "job_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.boolean  "completed",    :default => false
    t.integer  "target_id"
    t.string   "target_type"
    t.boolean  "success",      :default => false
  end

  create_table "clusters", :force => true do |t|
    t.string  "map_id"
    t.string  "name"
    t.integer "user_id"
  end

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "defense_ratio"
    t.integer  "worth"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "equipments", :force => true do |t|
    t.string  "klass"
    t.string  "title"
    t.text    "description"
    t.integer "hacking_bonus"
    t.integer "botnet_bonus"
    t.integer "defense_bonus"
    t.string  "special_bonus"
    t.float   "price"
    t.integer "level"
  end

  create_table "items", :force => true do |t|
    t.integer  "user_id"
    t.integer  "equipment_id"
    t.boolean  "equipped",     :default => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "jobs", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "type_id"
    t.integer  "difficulty"
    t.integer  "target_id"
    t.integer  "reward"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.boolean  "completed",              :default => false
    t.boolean  "success"
    t.integer  "complexity",             :default => 1
    t.integer  "hacking_ratio_required", :default => 0
    t.integer  "botnet_ratio_required",  :default => 0
  end

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "from_user_id"
    t.string   "klass"
    t.text     "message"
    t.boolean  "is_new",       :default => true
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "email",                                                                :default => "",    :null => false
    t.string   "encrypted_password",     :limit => 128,                                :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "botnet_ratio",                                                         :default => 10
    t.decimal  "money",                                 :precision => 10, :scale => 2, :default => 100.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "hacking_ratio",                                                        :default => 10
    t.string   "nickname"
    t.integer  "defense_ratio",                                                        :default => 10
    t.boolean  "notify",                                                               :default => false
  end

  add_index "users", ["nickname"], :name => "index_users_on_nickname", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
