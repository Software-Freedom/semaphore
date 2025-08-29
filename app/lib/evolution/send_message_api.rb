module Evolution
  class SendMessageApi
    include HTTParty
    base_uri ENV["EVOLUTION_URL"]

    headers "Content-Type" => "application/json",
            "apikey" => ENV["EVOLUTION_API_KEY"]

    class << self
      def send_plain_text(
        instance:, 
        number:, 
        text:,
        delay: 1000,
        link_preview: true,
        mentions_everyone: false,
        mentioned: nil,
        quoted: nil
      )
        body = {
          number: number,
          text: text,
          delay: delay,
          linkPreview: link_preview,
          mentionsEveryOne: mentions_everyone,
          mentioned: mentioned,
          quoted: quoted
        }.compact
  
        post("/message/sendText/#{instance}", body: body.to_json)
      end

      def send_media(
        instance:,
        number:, 
        media_type:, 
        mime_type:,
        media:,
        file_name:,
        caption: "",
        delay: 1000,
        link_preview: true,
        mentions_everyone: false,
        mentioned: nil,
        quoted: nil
      )
        body = {
          number: number,
          mediatype: media_type,
          mimetype: mime_type,
          caption: caption,
          media: media,
          fileName: file_name,
          delay: delay,
          linkPreview: link_preview,
          mentionsEveryOne: mentions_everyone,
          mentioned: mentioned,
          quoted: quoted
        }.compact
  
        post("/message/sendMedia/#{instance}", body: body.to_json)
      end
            
      def send_audio(
        instance:,
        number:, 
        audio:,
        delay: 1000,
        link_preview: true,
        mentions_everyone: false,
        mentioned: nil,
        quoted: nil
      )
        body = {
          number: number,
          audio: audio,
          delay: delay,
          linkPreview: link_preview,
          mentionsEveryOne: mentions_everyone,
          mentioned: mentioned,
          quoted: quoted
        }.compact

        post("/message/sendWhatsAppAudio/#{instance}", body: body.to_json)
      end
    end
  end
end
