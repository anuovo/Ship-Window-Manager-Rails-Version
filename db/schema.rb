# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_04_22_000004) do

  create_table "ship_window_range_items", force: :cascade do |t|
    t.integer "ship_window_range_id", null: false
    t.integer "item_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["item_id"], name: "index_ship_window_range_items_on_item_id"
    t.index ["ship_window_range_id", "item_id"], name: "idx_range_items_unique_range_item", unique: true
    t.index ["ship_window_range_id"], name: "idx_range_items_on_range_id"
  end

  create_table "ship_window_ranges", force: :cascade do |t|
    t.integer "program_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["program_id"], name: "index_ship_window_ranges_on_program_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer "program_id", null: false
    t.string "class_name", null: false
    t.string "item_code", null: false
    t.string "description", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["program_id", "item_code"], name: "index_items_on_program_id_and_item_code", unique: true
    t.index ["program_id"], name: "index_items_on_program_id"
  end

  create_table "programs", force: :cascade do |t|
    t.string "name", null: false
    t.date "ship_start_date", null: false
    t.date "ship_end_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "items", "programs"
  add_foreign_key "ship_window_range_items", "items"
  add_foreign_key "ship_window_range_items", "ship_window_ranges"
  add_foreign_key "ship_window_ranges", "programs"
end
