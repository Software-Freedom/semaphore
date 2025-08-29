class CreateEvolutionMessage < ActiveRecord::Migration[7.0]
  def change
    create_table :evolution_messages do |t|
      t.string :evolution_instance_id
      t.string :evolution_chat_id
      t.string :evolution_remote_id
      t.string :chatwoot_account_id
      t.string :chatwoot_account_token
      t.string :chatwoot_conversation_id
      t.string :chatwoot_message_id
      
      t.string :event
      t.json :payload
      
      t.boolean :sent, default: false
      t.boolean :retried, default: false
      t.boolean :deleted, default: false

      t.datetime :sent_at

      t.timestamps
    end

    add_index :evolution_messages,
              [:chatwoot_conversation_id, :sent, :created_at],
              name: "index_evolution_messages_on_conversation_sent_created_at"
  end
end
