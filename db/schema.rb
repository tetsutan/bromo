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

ActiveRecord::Schema.define(version: 20140718135023) do

  create_table "groups", force: true do |t|
    t.string "name"
    t.string "image_path"
  end

  create_table "media_informations", force: true do |t|
    t.string   "media_name"
    t.datetime "schedule_updated_at"
  end

  create_table "schedules", force: true do |t|
    t.string  "media_name"
    t.string  "channel_name"
    t.string  "title"
    t.string  "description"
    t.integer "from_time"
    t.integer "to_time"
    t.string  "finger_print"
    t.integer "recorded",     default: 0
    t.string  "file_path"
    t.string  "image_path"
    t.string  "reserved_1"
    t.string  "reserved_2"
    t.string  "reserved_3"
    t.integer "video"
    t.integer "group_id"
    t.string  "search_text"
  end

end
