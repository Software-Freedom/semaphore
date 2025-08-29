module Chatwoot
  class GetConversationService
    def self.call(account_token:, account_id:, remote_jid:)
      new(account_token: account_token, account_id: account_id, remote_jid: remote_jid).call
    end

    def initialize(account_token:, account_id:, remote_jid:)
      @account_token = account_token
      @account_id = account_id
      @remote_jid = remote_jid
    end

    def call
      response = Chatwoot::ConversationApi.conversations_filter(
        account_token: @account_token,
        account_id: @account_id
      )

      data = response.parsed_response.with_indifferent_access
      payload = data.dig(:payload) || []

      conversation = payload.find do |conv|
        conv.dig(:meta, :sender, :identifier) == @remote_jid
      end

      conversation.to_h.with_indifferent_access
    end
  end
end
