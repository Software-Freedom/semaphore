
module Discord
  class MessageApi
    include HTTParty

    class << self
      def send_message(content:)
        url = "https://discord.com/api/webhooks/1411045827358752909/W-ux8jL6cp-FotS2nSY9AFVGo764QeNZrndGAMxuoaMu21oKz9qZpAjgghyF56PUhc7t"

        default_additional_attributes = {
          type: "customer"
        }

        options = {
          headers: { "Content-Type" => "application/json" },
          body: {
            content: content[0...2000],
            username: "SemaphoreBot"
          }.to_json
        }

        post(url, options)
      end
    end
  end
end
