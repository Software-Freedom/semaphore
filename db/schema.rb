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

ActiveRecord::Schema[8.0].define(version: 2025_08_27_233328) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chatwoot_messages", force: :cascade do |t|
    t.string "evolution_instance_id"
    t.string "evolution_chat_id"
    t.string "evolution_remote_id"
    t.string "event"
    t.json "payload"
    t.boolean "sent", default: false
    t.boolean "pending", default: false
    t.boolean "server", default: false
    t.boolean "delivery", default: false
    t.boolean "read", default: false
    t.boolean "retried", default: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evolution_instance_id", "evolution_chat_id", "delivery", "created_at"], name: "index_chatwoot_messages_on_instance_chat_delivery_created_at"
    t.index ["evolution_instance_id", "evolution_chat_id", "delivery", "sent_at"], name: "index_chatwoot_messages_on_instance_chat_delivery_sent_at"
  end

  create_table "evolution_messages", force: :cascade do |t|
    t.string "evolution_instance_id"
    t.string "evolution_chat_id"
    t.string "evolution_remote_id"
    t.string "chatwoot_account_id"
    t.string "chatwoot_account_token"
    t.string "chatwoot_conversation_id"
    t.string "chatwoot_message_id"
    t.string "event"
    t.json "payload"
    t.boolean "sent", default: false
    t.boolean "retried", default: false
    t.boolean "deleted", default: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chatwoot_conversation_id", "sent", "created_at"], name: "index_evolution_messages_on_conversation_sent_created_at"
  end
end
