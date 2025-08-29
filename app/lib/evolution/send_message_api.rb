module Evolution
  class SendMessageApi
    include HTTParty
    base_uri "http://localhost:8080"

    headers "Content-Type" => "application/json",
            "apikey" => "429683C4C977415CAAFCCE10F7D57E11"

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
