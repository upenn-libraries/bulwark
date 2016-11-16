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

ActiveRecord::Schema.define(version: 20161116143346) do

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       null: false
    t.string   "user_type"
    t.string   "document_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type"
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "metadata_builders", force: :cascade do |t|
    t.string   "parent_repo"
    t.string   "source"
    t.string   "preserve"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "repo_id"
    t.integer  "metadata_source_id"
    t.datetime "last_xml_generated"
    t.string   "xml_preview"
  end

  add_index "metadata_builders", ["metadata_source_id"], name: "index_metadata_builders_on_metadata_source_id"
  add_index "metadata_builders", ["repo_id"], name: "index_metadata_builders_on_repo_id"

  create_table "metadata_sources", force: :cascade do |t|
    t.string   "path"
    t.string   "view_type",             default: "horizontal"
    t.integer  "num_objects",           default: 1
    t.integer  "x_start",               default: 1
    t.integer  "y_start",               default: 1
    t.integer  "x_stop",                default: 1
    t.integer  "y_stop",                default: 1
    t.text     "original_mappings"
    t.string   "root_element"
    t.string   "parent_element"
    t.text     "user_defined_mappings"
    t.text     "children"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "metadata_builder_id"
    t.string   "source_type"
    t.datetime "last_extraction"
    t.datetime "last_settings_updated"
    t.integer  "z",                     default: 1
    t.string   "input_source"
    t.string   "identifier"
  end

  add_index "metadata_sources", ["metadata_builder_id"], name: "index_metadata_sources_on_metadata_builder_id"

# Could not dump table "repos" because of following NoMethodError
#   undefined method `[]' for nil:NilClass

  create_table "roles", force: :cascade do |t|
    t.string "name"
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id", "user_id"], name: "index_roles_users_on_role_id_and_user_id"
  add_index "roles_users", ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id"

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.string   "user_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "guest",                  default: false
    t.string   "job_activity"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "version_control_agents", force: :cascade do |t|
    t.string   "vc_type"
    t.string   "remote_path"
    t.integer  "repo_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "version_control_agents", ["repo_id"], name: "index_version_control_agents_on_repo_id"

end
