class Evolution::SendMessageJob < ApplicationJob
  queue_as :default

  sidekiq_options(
    lock: :until_executed,
    lock_ttl: 10.seconds,
    unique_args: ->(args) { args[0] }
  )

  def perform(lock_key, id)
    message = Chatwoot::Message.lock("FOR UPDATE SKIP LOCKED").find_by_id(id)

    return unless message
    return if message.delivery?

    begin
      response = nil
      responses = []
      instance = message.evolution_instance_id
      number = message.evolution_chat_id

      if message.audio?
        message.attachments.each do |attachment|
          audio = attachment["data_url"]

          responses << Evolution::SendMessageApi.send_audio(
            instance: instance,
            number: number,
            audio: audio
          )
        end
      elsif message.media?
        message.attachments.each do |attachment|
          media_type = attachment["file_type"]
          media = attachment["data_url"]
          file_name_with_ext = File.basename(URI.parse(media).path)
          mime_type = File.extname(file_name_with_ext)
          file_name = "#{File.basename(file_name_with_ext, ".*")}#{mime_type}"

          media_type = "document" if mime_type.to_s.in?(['.gif', '.svg', '.tiff', '.tif'])
          
          responses << Evolution::SendMessageApi.send_media(
            instance: instance,
            number: number,
            media_type: media_type, 
            mime_type: nil,
            media: media,
            file_name: file_name,
          )
        end
      else
        payload = message.payload
        text = if payload[:content]
          payload[:content]
            .gsub(/(?<!\*)\*((?!\s)([^\n*]+?)(?<!\s))\*(?!\*)/, '_\1_')   # Substitui * por _
            .gsub(/\*{2}((?!\s)([^\n*]+?)(?<!\s))\*{2}/, '*\1*')          # Substitui ** por *
            .gsub(/~{2}((?!\s)([^\n*]+?)(?<!\s))~{2}/, '~\1~')             # Substitui ~~ por ~
            .gsub(/(?<!`)`((?!\s)([^`*]+?)(?<!\s))`(?!`)/, '```\1```')    # Substitui ` por ```
        else
          payload[:content]
        end

        response = Evolution::SendMessageApi.send_plain_text(
          instance: instance,
          number: number,
          text: text
        )
      end
    
      response = responses.last if responses.any?
      remote_id = response.parsed_response.with_indifferent_access.dig(:key, :id)

      if remote_id.present?
        message.update(sent: true, sent_at: DateTime.current, evolution_remote_id: remote_id)
      end

      Evolution::RetryMessageJob.set(wait: 2.minutes).perform_later(lock_key, id)

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
