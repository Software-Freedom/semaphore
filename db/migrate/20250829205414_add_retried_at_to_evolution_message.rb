class AddRetriedAtToEvolutionMessage < ActiveRecord::Migration[8.0]
  def change
    add_column :evolution_messages, :retried_at, :datetime
    add_column :evolution_messages, :delivery_at, :datetime
  end
end
