class AddRetriedAtAndDeliveryAtToChatwootMessage < ActiveRecord::Migration[8.0]
  def change
    add_column :chatwoot_messages, :retried_at, :datetime
    add_column :chatwoot_messages, :delivery_at, :datetime
  end
end
