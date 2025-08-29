class CreateChatwootMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :chatwoot_messages do |t|
      t.string :evolution_instance_id
      t.string :evolution_chat_id
      t.string :evolution_remote_id
      t.string :event
      t.json :payload

      t.boolean :sent, default: false
      t.boolean :pending, default: false
      t.boolean :server, default: false
      t.boolean :delivery, default: false
      t.boolean :read, default: false
      t.boolean :retried, default: :false

      t.datetime :sent_at

      t.timestamps
    end

    add_index :chatwoot_messages, 
              [:evolution_instance_id, :evolution_chat_id, :delivery, :created_at], 
              name: 'index_chatwoot_messages_on_instance_chat_delivery_created_at'

    add_index :chatwoot_messages,
              [:evolution_instance_id, :evolution_chat_id, :delivery, :sent_at],
              name: 'index_chatwoot_messages_on_instance_chat_delivery_sent_at'
  end
end
