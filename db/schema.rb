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

ActiveRecord::Schema.define(version: 20150305013950) do

  create_table "groups", force: :cascade do |t|
    t.text "name",       limit: 255
    t.text "image_path", limit: 255
  end

  create_table "media_informations", force: :cascade do |t|
    t.string   "media_name",          limit: 255
    t.datetime "schedule_updated_at"
  end

  create_table "schedules", force: :cascade do |t|
    t.string   "media_name",   limit: 255
    t.string   "channel_name", limit: 255
    t.text     "title",        limit: 255
    t.text     "description",  limit: 255
    t.integer  "from_time"
    t.integer  "to_time"
    t.text     "finger_print", limit: 255
    t.integer  "recorded",                 default: 0
    t.text     "file_path",    limit: 255
    t.text     "image_path",   limit: 255
    t.text     "reserved_1",   limit: 255
    t.text     "reserved_2",   limit: 255
    t.text     "reserved_3",   limit: 255
    t.integer  "video"
    t.integer  "group_id"
    t.text     "search_text",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
