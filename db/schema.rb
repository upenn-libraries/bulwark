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

ActiveRecord::Schema.define(version: 20210114191712) do

  create_table "batches", force: :cascade do |t|
    t.text     "queue_list",      limit: 4294967295
    t.text     "directive_names", limit: 4294967295
    t.string   "email",           limit: 255
    t.datetime "start"
    t.datetime "end"
    t.string   "status",          limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,   null: false
    t.string   "user_type",     limit: 255
    t.string   "document_id",   limit: 255
    t.string   "title",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "document_type", limit: 255
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id", using: :btree

  create_table "bulk_imports", force: :cascade do |t|
    t.integer  "created_by_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "digital_object_imports", force: :cascade do |t|
    t.integer  "bulk_import_id", limit: 4
    t.string   "status",         limit: 255
    t.text     "process_errors", limit: 65535
    t.text     "import_data",    limit: 16777215
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "endpoints", force: :cascade do |t|
    t.string   "source",       limit: 255
    t.string   "destination",  limit: 255
    t.string   "content_type", limit: 255
    t.string   "protocol",     limit: 255
    t.text     "parameters",   limit: 4294967295
    t.text     "problems",     limit: 4294967295
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "repo_id",      limit: 4
    t.string   "fetch_method", limit: 255
  end

  add_index "endpoints", ["repo_id"], name: "index_endpoints_on_repo_id", using: :btree

  create_table "manifests", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.text     "content",               limit: 4294967295
    t.text     "validation_problems",   limit: 4294967295
    t.string   "owner",                 limit: 255
    t.string   "steps",                 limit: 255
    t.string   "last_action_performed", limit: 255
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "metadata_builders", force: :cascade do |t|
    t.string   "parent_repo",              limit: 255
    t.string   "source",                   limit: 255
    t.string   "preserve",                 limit: 255
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "repo_id",                  limit: 4
    t.integer  "metadata_source_id",       limit: 4
    t.datetime "last_xml_generated"
    t.text     "xml_preview",              limit: 4294967295
    t.datetime "last_file_checks"
    t.text     "generated_metadata_files", limit: 65535
  end

  add_index "metadata_builders", ["metadata_source_id"], name: "index_metadata_builders_on_metadata_source_id", using: :btree
  add_index "metadata_builders", ["repo_id"], name: "index_metadata_builders_on_repo_id", using: :btree

  create_table "metadata_sources", force: :cascade do |t|
    t.string   "path",                  limit: 255
    t.string   "view_type",             limit: 255,        default: "horizontal"
    t.integer  "num_objects",           limit: 4,          default: 1
    t.integer  "x_start",               limit: 4,          default: 1
    t.integer  "y_start",               limit: 4,          default: 1
    t.integer  "x_stop",                limit: 4,          default: 1
    t.integer  "y_stop",                limit: 4,          default: 1
    t.text     "original_mappings",     limit: 4294967295
    t.string   "root_element",          limit: 255
    t.string   "parent_element",        limit: 255
    t.text     "user_defined_mappings", limit: 4294967295
    t.text     "children",              limit: 4294967295
    t.text     "parameters",            limit: 4294967295
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                                                      null: false
    t.integer  "metadata_builder_id",   limit: 4
    t.string   "source_type",           limit: 255
    t.datetime "last_extraction"
    t.datetime "last_settings_updated"
    t.integer  "z",                     limit: 4,          default: 1
    t.string   "input_source",          limit: 255
    t.string   "identifier",            limit: 255
    t.string   "file_field",            limit: 255
    t.text     "remote_location",       limit: 65535
  end

  add_index "metadata_sources", ["metadata_builder_id"], name: "index_metadata_sources_on_metadata_builder_id", using: :btree

  create_table "repos", force: :cascade do |t|
    t.string   "human_readable_name",        limit: 255
    t.string   "description",                limit: 255
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.string   "metadata_subdirectory",      limit: 255
    t.string   "assets_subdirectory",        limit: 255
    t.string   "derivatives_subdirectory",   limit: 255
    t.string   "file_extensions",            limit: 255
    t.string   "metadata_source_extensions", limit: 255
    t.boolean  "ingested"
    t.string   "preservation_filename",      limit: 255
    t.string   "review_status",              limit: 255
    t.integer  "metadata_builder_id",        limit: 4
    t.integer  "version_control_agent_id",   limit: 4
    t.string   "owner",                      limit: 255
    t.string   "steps",                      limit: 255
    t.string   "admin_subdirectory",         limit: 255
    t.string   "unique_identifier",          limit: 255
    t.string   "thumbnail",                  limit: 255
    t.text     "problem_files",              limit: 4294967295
    t.text     "images_to_render",           limit: 4294967295
    t.text     "file_display_attributes",    limit: 4294967295
    t.datetime "last_external_update"
    t.string   "initial_stop",               limit: 255
    t.integer  "endpoint_id",                limit: 4
    t.string   "last_action_performed",      limit: 255
    t.string   "queued",                     limit: 255
    t.text     "thumbnail_location",         limit: 65535
    t.boolean  "new_format",                                    default: false
  end

  add_index "repos", ["endpoint_id"], name: "index_repos_on_endpoint_id", using: :btree
  add_index "repos", ["metadata_builder_id"], name: "index_repos_on_metadata_builder_id", using: :btree
  add_index "repos", ["version_control_agent_id"], name: "index_repos_on_version_control_agent_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "role_id", limit: 4
    t.integer "user_id", limit: 4
  end

  add_index "roles_users", ["role_id", "user_id"], name: "index_roles_users_on_role_id_and_user_id", using: :btree
  add_index "roles_users", ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id", using: :btree

  create_table "searches", force: :cascade do |t|
    t.text     "query_params", limit: 65535
    t.integer  "user_id",      limit: 4
    t.string   "user_type",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255,        default: "",    null: false
    t.string   "encrypted_password",     limit: 255,        default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.boolean  "guest",                                     default: false
    t.text     "job_activity",           limit: 4294967295
    t.integer  "failed_attempts",        limit: 4,          default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "version_control_agents", force: :cascade do |t|
    t.string   "vc_type",     limit: 255
    t.string   "remote_path", limit: 255
    t.integer  "repo_id",     limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "version_control_agents", ["repo_id"], name: "index_version_control_agents_on_repo_id", using: :btree

  add_foreign_key "endpoints", "repos"
  add_foreign_key "metadata_builders", "metadata_sources"
  add_foreign_key "metadata_builders", "repos"
  add_foreign_key "metadata_sources", "metadata_builders"
  add_foreign_key "repos", "endpoints"
  add_foreign_key "repos", "metadata_builders"
  add_foreign_key "repos", "version_control_agents"
  add_foreign_key "version_control_agents", "repos"
end
