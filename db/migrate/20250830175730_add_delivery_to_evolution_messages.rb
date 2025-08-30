class AddDeliveryToEvolutionMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :evolution_messages, :delivery, :boolean, default: false
  end
end
