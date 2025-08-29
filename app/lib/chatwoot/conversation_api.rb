module Chatwoot
  class ConversationApi
    include HTTParty
    base_uri "https://www.chatfly.com.br/api/v1"

    class << self
      def conversations_filter(account_token:, account_id:)
        body = {
          payload: []
        }

        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer #{account_token}",
          "api_access_token" => account_token
        }

        post(
          "/accounts/#{account_id}/conversations/filter",
          body: body.to_json,
          headers: headers
        )
      end
    end
  end
end
