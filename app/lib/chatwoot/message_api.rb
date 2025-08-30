require 'base64'
require 'stringio'
require "marcel"

module Chatwoot
  class MessageApi
    include HTTParty
    base_uri ENV["CHATWOOT_URL"]

    class << self

      def create_new_message(
        account_token:,
        account_id:,
        conversation_id:,
        content:,
        message_type: 'incoming',
        private_message: false,
        content_type: "text",
        content_attributes: {}
      )
        url = "/accounts/#{account_id}/conversations/#{conversation_id}/messages"

        options = {
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{account_token}",
            "api_access_token" => account_token
          },
          body: {
            content: content,
            message_type: message_type,
            private: private_message,
            content_type: content_type,
            content_attributes: content_attributes
          }.to_json
        }

        post(url, options)
      end

      def create_new_message_attachment(
        account_token:, 
        account_id:, 
        conversation_id:, 
        content:, 
        attachments:, 
        message_type: "incoming", 
        private_message: false
      )

        url = "/accounts/#{account_id}/conversations/#{conversation_id}/messages"

        temp_files = []
        attachments.each do |base64_string|
          decoded_data = Base64.decode64(base64_string)
          mime_type = Marcel::MimeType.for(StringIO.new(decoded_data))
          extension = Rack::Mime::MIME_TYPES.invert[mime_type]
          filename = "whatsapp_#{Time.current.to_i}#{extension}"

          extension = ".oga" if mime_type == "audio/opus"

          temp_file = Tempfile.new([File.basename(filename, '.*'), extension])
          temp_file.binmode
          temp_file.write(decoded_data)
          temp_file.rewind

          temp_files << temp_file
        end

        begin
          options = {
            headers: {
              "Content-Type" => "multipart/form-data; boundary=----WebKitFormBoundaryk0bUDhpDyiZRIE4F",
              "Authorization" => "Bearer #{account_token}",
              "api_access_token" => account_token
            },
            body: {
              content: content,
              attachments: temp_files,
              message_type: message_type,
              private: private_message
            }
          }

          post(url, options)
        ensure
          temp_files.each do |file|
            file.close
            file.unlink
          end
        end
      end

      def delete_message(account_token:, account_id:, conversation_id:, message_id:)
        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{account_token}",
          "api_access_token" => account_token
        }

        delete("/accounts/#{account_id}/conversations/#{conversation_id}/messages/#{message_id}",
                headers: headers)
      end
    end
  end
end
