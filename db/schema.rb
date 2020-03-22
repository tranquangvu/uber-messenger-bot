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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160818081221) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_admins_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true, using: :btree
  end

  create_table "bookmarks", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.integer  "user_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "active",     default: true
    t.index ["user_id"], name: "index_bookmarks_on_user_id", using: :btree
  end

  create_table "conversations", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "current_question"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["user_id"], name: "index_conversations_on_user_id", using: :btree
  end

  create_table "feedbacks", force: :cascade do |t|
    t.string   "content"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_feedbacks_on_user_id", using: :btree
  end

  create_table "rides", force: :cascade do |t|
    t.string   "location"
    t.string   "destination"
    t.integer  "user_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.float    "location_longitude"
    t.float    "location_latitude"
    t.float    "destination_longitude"
    t.float    "destination_latitude"
    t.string   "product"
    t.boolean  "active",                default: true
    t.string   "product_id"
    t.string   "request_id"
    t.string   "payment_method_type"
    t.string   "payment_method_id"
    t.string   "surge_confirmation_id"
    t.index ["user_id"], name: "index_rides_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "messenger_id"
    t.string   "access_token"
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "token_created_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "promo_code"
    t.string   "uuid"
  end

  add_foreign_key "bookmarks", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "rides", "users"
end
