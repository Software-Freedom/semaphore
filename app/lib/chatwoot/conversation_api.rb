module Chatwoot
  class ConversationApi
    include HTTParty
    base_uri ENV["CHATWOOT_URL"]

    class << self
      def conversations_filter(account_token:, account_id:)
        url = "/accounts/#{account_id}/conversations/filter"
        options = {
          headers:{
            "Content-Type": "application/json",
            "Authorization": "Bearer #{account_token}",
            "api_access_token": account_token
          },
          body: {
            payload: []
          }.to_json
        }

        post(url, options)
      end

      def create_new_conversation(
        account_token:, 
        account_id:,
        inbox_id:,
        contact_id:,
        source_id: SecureRandom.uuid,
        status: "open",
        assignee_id: nil,
        team_id: nil,
        snoozed_until: Time.now.utc.iso8601
      )
        url = "/accounts/#{account_id}/conversations"
        options = {
          headers:{
            "Content-Type": "application/json",
            "Authorization": "Bearer #{account_token}",
            "api_access_token": account_token
          },
          body: {
            source_id: source_id,
            inbox_id: inbox_id,
            contact_id: contact_id,
            additional_attributes: {},
            custom_attributes: {},
            status: status,
            assignee_id: assignee_id,
            team_id: team_id,
            snoozed_until: snoozed_until,
            message: {}
          }.to_json
        }

        post(url, options)
      end
    end
  end
end