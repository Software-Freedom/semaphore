module Evolution
  class Message < ApplicationRecord
    self.table_name = "evolution_messages"
  
    MESSAGE_TYPE = {
      CONVERSATION: "conversation",
      MESSAGE: "message",
      LOCATION_MESSAGE: "locationMessage",
      CONTACT_MESSAGE: "contactMessage",
      CONTACT_ARRAY_MESSAGE: "contactsArrayMessage",
      IMAGE_MESSAGE: "imageMessage",
      AUDIO_MESSAGE: "audioMessage",
      VIDEO_MESSAGE: "videoMessage",
      DOCUMENT_MESSAGE: "documentMessage",
      STICKER_MESSAGE: "stickerMessage"
    }.freeze

    attribute :payload, :json, default: -> { {} }

    validates :evolution_instance_id, presence: true
    validates :evolution_chat_id, presence: true
    validates :chatwoot_account_id, presence: true
    validates :chatwoot_account_token, presence: true
    validates :event, presence: true
    validates :payload, presence: true
    validates :evolution_chat_id, exclusion: { in: ['status@broadcast'], message: "não pode ser %{value}" }

    before_validation :set_evolution_chat_id
    before_validation :set_evolution_remote_id
    before_validation :set_created_at
    before_destroy :clear_cache_lock 
    before_update :set_delivery_at, if: -> { delivery_changed?(to: true) }
    before_update :set_sent_at, if: -> { sent_changed?(to: true) }
    before_update :set_retried_at, if: -> { retried_changed?(to: true) }
    after_create_commit :enqueue_send_message
    after_update_commit :clear_cache_lock, if: -> { saved_change_to_sent?(to: true) }
    after_update_commit :enqueue_next_message, if: -> { saved_change_to_sent?(to: true) }

    def lock_key
      "evolution:message:conversation-#{chatwoot_conversation_id}"
    end

    def payload
      super.with_indifferent_access
    end

    def media?
      {
        image_message: data_message.dig(:imageMessage).present?,
        video_message: data_message.dig(:videoMessage).present?,
        document_message: data_message.dig(:documentMessage).present?,
        document_with_caption_message: data_message.dig(:documentWithCaptionMessage).present?,
        audio_message: data_message.dig(:audioMessage).present?,
        sticker_message: data_message.dig(:stickerMessage).present?,
        view_once_message_v2: data_message.dig(:viewOnceMessageV2).present?
      }.values.any?
    end

    def ephemeral_message?
      payload.dig(:data, :message, :ephemeralMessage, :message).present?
    end

    def data_message
      if ephemeral_message?
        payload.dig(:data, :message, :ephemeralMessage, :message)
      else
        payload.dig(:data, :message)
      end
    end

    def message_content_type
      {
        conversation: data_message[:conversation],
        image_message: data_message.dig(:imageMessage, :caption),
        video_message: data_message.dig(:videoMessage, :caption),
        extended_text_message: data_message.dig(:extendedTextMessage, :text),
        message_context_info: data_message.dig(:messageContextInfo, :stanzaId),
        sticker_message: nil,
        document_message: data_message.dig(:documentMessage, :caption),
        document_with_caption_message: data_message.dig(:documentWithCaptionMessage, :message, :documentMessage, :caption),
        audio_message: nil,
        contact_message: data_message.dig(:contactMessage, :vcard),
        contacts_array_message: data_message.dig(:contactsArrayMessage),
        location_message: data_message.dig(:locationMessage),
        live_location_message: data_message.dig(:liveLocationMessage),
        listMessage: data_message.dig(:list_message),
        list_response_message: data_message.dig(:listResponseMessage),
        view_once_message_v2: data_message.dig(:viewOnceMessageV2, :message, :imageMessage, :url) ||
                              data_message.dig(:viewOnceMessageV2, :message, :videoMessage, :url) ||
                              data_message.dig(:viewOnceMessageV2, :message, :audioMessage, :url)
      }
    end

    def chatwoot_content
      key, content = message_content_type.compact.first

      if content.is_a?(String) && content.include?('externalAdReplyBody|')
        content = content.split('externalAdReplyBody|').reject(&:empty?).join
      end

      if key.to_s.in?(["location_message", "live_location_message"])
        latitude = content[:degreesLatitude]
        longitude = content[:degreesLongitude]

        location_name = content[:name] ? "_Localidade #{content[:name]}\n" : ""
        location_address = content[:address] ? "_Endereço:_ #{content[:address]}\n" : ""

        content = "*Localização:*\n\n" \
                  "_Latitude:_ #{latitude} \n" \
                  "_Longitude:_ #{longitude} \n" \
                  "#{location_name}" \
                  "#{location_address}" \
                  "_URL:_ https://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}"

        return content;
      end

      if key.to_s == "contact_message"
        vcard_data = content.split("\n")
        contact_info = {}

        vcard_data.each do |line|
          key, value = line.split(":", 2)
          contact_info[key] = value if key && value
        end

        content = "*Contato:*\n\n"
        content += "_Nome:_ #{contact_info['FN']}" if contact_info['FN']

        contact_info.each do |key, value|
          if (key.start_with?('item') && key.include?('TEL')) || key.include?('TEL')
            content += "\n_Número:_ #{value}"
          end
        end

        return content
      end

      if key.to_s == "contacts_array_message"
        content = content[:contacts].map do |contact|
          vcard_data = contact[:vcard].split("\n")
          contact_info = {}

          vcard_data.each do |line|
            key, value = line.split(":", 2)
            contact_info[key] = value if key && value
          end

          formatted_contact = "*Contato:*\n\n"
          formatted_contact += "_Nome:_ #{contact[:displayName]}" if contact[:displayName]

          contact_info.each do |key, value|
            if (key.start_with?('item') && key.include?('TEL')) || key.include?('TEL')
              formatted_contact += "\n_Número:_ #{value}"
            end
          end

          formatted_contact
        end

        return content.join("\n\n")
      end
      
      content
    end

    def chatwoot_attachments
      return [] unless media?

      [payload.dig(:data, :message, :base64)]
    end

    ###########
    # ACTIONS #
    ###########
    def set_evolution_chat_id
      self.evolution_chat_id ||= payload.dig(:data, :key, :remoteJid)
    end

    def set_evolution_remote_id
      self.evolution_remote_id ||= payload.dig(:data, :key, :id)
    end

    def set_created_at
      self.created_at ||= payload.dig(:date_time)
    end

    def set_delivery_at
      self.delivery_at ||= DateTime.current
    end

    def set_sent_at
      self.sent_at ||= DateTime.current
    end

    def set_retried_at
      self.retried_at ||= DateTime.current
    end

    def enqueue_send_message
      return unless Rails.cache.write(lock_key, true, unless_exist: true, expires_in: 30.seconds)
 
      Chatwoot::SendMessageJob.set(wait: 2.seconds).perform_later(lock_key, id)
    end

    def clear_cache_lock
      Rails.cache.delete(lock_key)
    end

    def enqueue_next_message
      next_message = self.class.where(chatwoot_conversation_id: chatwoot_conversation_id, sent: false)
                                .where.not(id: id)
                                .order(:created_at)
                                .first
      return unless next_message

      next_message.enqueue_send_message
    end
  end
end
