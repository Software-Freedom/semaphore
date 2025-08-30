class Chatwoot::SendMessageJob < ApplicationJob
  queue_as :default

  sidekiq_options(
    lock: :until_executed,
    lock_ttl: 5.seconds,
    unique_args: ->(args) { args[0] }
  )

  def perform(lock_key, id)
    message = Evolution::Message.find_by_id(id)

    return unless message

    begin
      message_type = message.payload.dig(:data, :messageType)
      instance = message.evolution_instance_id
      content = message.chatwoot_content
      account_token = message.chatwoot_account_token
      account_id = message.chatwoot_account_id
      remote_jid = message.evolution_chat_id
      attachments = message.chatwoot_attachments
      contact_name = message.payload.dig(:data, :pushName)

      conversation = Chatwoot::FindOrCreateConversationService.call(account_token: account_token, 
                                                                    account_id: account_id, 
                                                                    remote_jid: remote_jid,
                                                                    instance_name: instance,
                                                                    contact_name: contact_name)
      conversation_id = conversation["id"]

      unless conversation_id
        details = "Código: #{response.code}\n"
        message_info = "Corpo: #{response.body}\n"
        content = "Não foi possivel encontrada a conversa Evolution::Message ID: #{id}, #{details}#{message_info}"
        Discord::MessageApi.send_message(content: content)
        return
      end

      if message.media?
        response = Chatwoot::MessageApi.create_new_message_attachment(account_token: account_token,
                                                                        account_id: account_id,
                                                                        conversation_id: conversation_id,
                                                                        content: content,
                                                                        attachments: attachments)
      else
        response = Chatwoot::MessageApi.create_new_message(account_token: account_token,
                                                            account_id: account_id,
                                                            conversation_id: conversation_id,
                                                            content: content)
      end

      unless response.success?
        details = "Código: #{response.code}\n"
        message_info = "Corpo: #{response.body}\n"
        content = "#{details}#{message_info}"

        Discord::MessageApi.send_message(content: content)
      end

      if response.success?
        message_id = response["id"]
        message.update(chatwoot_message_id: message_id, sent: true, delivery: true)
      elsif !message.retried?
        message.update(retried: true)

        Chatwoot::SendMessageJob.set(wait: 6.seconds).perform_later(lock_key, id)
      end

    rescue StandardError => e
      message.clear_cache_lock
      message.enqueue_next_message

      details = "Erro: #{e.class} - #{e.message}\n"
      message_info = "ID da Mensagem: #{id}\n"
      backtrace_info = "Backtrace:\n#{e.backtrace.join("\n")}"

      Discord::MessageApi.send_message(
        content: "#{details}#{message_info}#{backtrace_info}"
      )
    end
  end
end
