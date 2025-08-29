class Chatwoot::Message < ApplicationRecord
  self.table_name = "chatwoot_messages"

  attribute :payload, :json, default: -> { {} }

  EVENTS = {
    MESSAGE_CREATED: "message_created"
  }.freeze

  MESSAGE_TYPE = {
    INCOMING: "incoming",
    OUTGOING: "outgoing"
  }.freeze

  # Validações
  validates :evolution_instance_id, presence: true
  validates :evolution_chat_id, presence: true
  validates :event, presence: true
  validates :payload, presence: true

  before_validation :set_evolution_chat_id
  before_validation :set_created_at
  before_destroy :clear_cache_lock 
  before_update :lock_delivery, if: -> { delivery_changed?(to: true) }
  before_update :set_delivery_at, if: -> { delivery_changed?(to: true) }
  after_create_commit :enqueue_send_message
  after_update_commit :clear_retry_message, if: -> { saved_change_to_delivery?(to: true) }
  after_update_commit :clear_cache_lock, if: -> { saved_change_to_delivery?(to: true) }
  after_update_commit :enqueue_next_message, if: -> { saved_change_to_delivery?(to: true) }

  def lock_key
    "chatwoot:message:conversation-#{evolution_instance_id}-#{evolution_chat_id}"
  end

  def lock_delivery_key
    "chatwoot:message:delivery-#{evolution_remote_id}"
  end

  def payload
    super.with_indifferent_access
  end

  def media?
    payload.dig(:attachments).try(:any?)
  end

  def audio?
    media? && attachments.first["file_type"] == "audio"
  end

  def attachments
    payload.dig(:attachments) || []
  end

  def set_evolution_chat_id
    self.evolution_chat_id ||= payload.dig(:conversation, :meta, :sender, :identifier) ||
                               payload.dig(:conversation, :meta, :sender, :phone_number)&.delete("+")
  end

  def set_created_at
    self.created_at ||= payload.dig(:created_at)
  end

  def set_delivery_at
    self.delivery_at ||= DateTime.current
  end

  # callbacks
  def enqueue_send_message
    return unless Rails.cache.write(lock_key, true, unless_exist: true, expires_in: 2.minutes)

    return if siblings_message_in_processing?

    Evolution::SendMessageJob.set(wait: 1.second).perform_later(lock_key, id)
  end

  def clear_retry_message
    Evolution::RetryMessageJob.remove_scheduled(lock_key, id)
  end

  def clear_cache_lock
    Rails.cache.delete(lock_key)
  end

  def enqueue_next_message
    next_message = self.class.where(evolution_instance_id: evolution_instance_id,
                                    evolution_chat_id: evolution_chat_id,
                                    delivery: false)
                              .where.not(id: id)
                              .order(:created_at)
                              .first

    next_message.enqueue_send_message if next_message
  end
  
  def lock_delivery
    Rails.cache.write(lock_delivery_key, true, expires_in: 20.seconds)
  end

  private

  def siblings_message_in_processing?
    messages = self.class.where(evolution_instance_id: evolution_instance_id,
                                evolution_chat_id: evolution_chat_id,
                                delivery: false)
                          .where.not(id: id)
                          .where.not(sent_at: nil)
    messages.exists?
  end
end
