
module Chatwoot
  class InboxApi
    include HTTParty
    base_uri ENV["CHATWOOT_URL"]

    class << self
      def list_all_inboxes(account_token:, account_id:)
        url = "/accounts/#{account_id}/inboxes"

        options = {
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{account_token}",
            "api_access_token" => account_token
          }
        }

        get(url, options)
      end
    end
  end
end
