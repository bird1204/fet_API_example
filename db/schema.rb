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

ActiveRecord::Schema.define(:version => 20131120043226) do

  create_table "features", :force => true do |t|
    t.integer  "product_id"
    t.integer  "os"
    t.boolean  "features1"
    t.boolean  "features2"
    t.boolean  "features3"
    t.boolean  "features4"
    t.boolean  "features5"
    t.boolean  "features6"
    t.boolean  "features7"
    t.boolean  "features8"
    t.boolean  "features9"
    t.boolean  "features10"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "features", ["product_id"], :name => "index_features_on_product_id"

  create_table "product_images", :force => true do |t|
    t.integer  "categorized"
    t.string   "imageable_type"
    t.integer  "imageable_id"
    t.string   "file"
    t.string   "type_text",      :default => "product"
    t.string   "url_origin"
    t.string   "url_big"
    t.string   "url_medium"
    t.string   "url_small"
    t.string   "url_thumb"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  create_table "product_spec_displays", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.integer  "spec_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "product_spec_displays", ["product_id"], :name => "index_product_spec_displays_on_product_id"
  add_index "product_spec_displays", ["spec_id"], :name => "index_product_spec_displays_on_spec_id"

  create_table "products", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.text     "info"
    t.integer  "product_type"
    t.integer  "brand_id"
    t.integer  "reviews"
    t.string   "market_date"
    t.boolean  "status"
    t.boolean  "is_info_trans"
    t.boolean  "is_spec_trans"
    t.boolean  "is_pic_trans"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "products", ["brand_id"], :name => "index_products_on_brand_id"

  create_table "spec_classes", :force => true do |t|
    t.string   "name"
    t.string   "name_en"
    t.integer  "sort"
    t.integer  "hall_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "spec_class_id"
  end

  add_index "spec_classes", ["hall_id"], :name => "index_spec_classes_on_hall_id"

  create_table "specs", :force => true do |t|
    t.string   "name"
    t.string   "name_en"
    t.integer  "spec_class_id"
    t.string   "remark"
    t.integer  "sort"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "spec_id"
  end

  add_index "specs", ["spec_class_id"], :name => "index_specs_on_spec_class_id"

end
