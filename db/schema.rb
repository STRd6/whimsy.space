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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151017175726) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "people", id: false, force: :cascade do |t|
    t.integer "id"
    t.text    "email",                         null: false
    t.text    "domain",                        null: false
    t.text    "persistent_token",              null: false
    t.json    "filesystem",       default: []
  end

  add_index "people", ["domain"], name: "people_domain_key", unique: true, using: :btree
  add_index "people", ["email"], name: "people_email_key", unique: true, using: :btree
  add_index "people", ["persistent_token"], name: "people_persistent_token_key", unique: true, using: :btree

  create_table "schema_info", id: false, force: :cascade do |t|
    t.integer "version", default: 0, null: false
  end

end
