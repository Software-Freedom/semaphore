class Chatwoot::SendMessageJob < ApplicationJob
  queue_as :default

  sidekiq_options(
    lock: :until_executed,
    lock_ttl: 5.seconds,
    unique_args: ->(args) { args[0] }
  )

  def perform(lock_key, id)
    message = Evolution::Message.lock("FOR UPDATE SKIP LOCKED").find_by_id(id)

    return unless message

    begin
      message_type = message.payload.dig(:data, :messageType)
      content = message.chatwoot_content
      account_token = message.chatwoot_account_token
      account_id = message.chatwoot_account_id
      remote_jid = message.evolution_chat_id
      conversation_id = message.chatwoot_conversation_id
      attachments = message.chatwoot_attachments

      if message.media?
        response = Chatwoot::MessageApi.create_new_message_attachment( account_token: account_token, 
                                                                        account_id: account_id, 
                                                                        conversation_id: conversation_id, 
                                                                        content: content,
                                                                        attachments: attachments)
      else
        response = Chatwoot::MessageApi.create_new_message( account_token: account_token, 
                                                            account_id: account_id, 
                                                            conversation_id: conversation_id, 
                                                            content: content)
      end

      if response.success?
        message_id = response.parsed_response.dig("id")
        message.update(chatwoot_message_id: message_id, sent: true, sent_at: DateTime.current)
      elsif !message.retried?
        message.update(retried: true, retried_at: DateTime.current)

        Chatwoot::SendMessageJob.set(wait: 3.seconds).perform_later(lock_key, id)
      end

    rescue StandardError => e
      message.clear_cache_lock
      Rails.logger.error("[Chatwoot::SendMessageJob] Failed to clear cache lock: #{e.message}")
    end
  end
end
