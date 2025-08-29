module Evolution
  class SendMessageApi
    include HTTParty
    base_uri ENV["EVOLUTION_URL"]

    headers "Content-Type" => "application/json",
            "apikey" => ENV["EVOLUTION_API_KEY"]

    class << self
      def send_plain_text(instance:, number:, text:, delay: nil, link_preview: true, mentions_everyone: false, mentioned: nil, quoted: nil)
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
    end
  end
end
