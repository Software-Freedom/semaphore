module Chatwoot
  class FindInboxService
    def self.call(**args)
      new(**args).call
    end

    def initialize(account_token:, account_id:, instance_name:)
      @account_token = account_token
      @account_id = account_id
      @instance_name = instance_name
    end

    def call
      inbox = find
      inbox.to_h.with_indifferent_access
    end

    private

    def find
      response = Chatwoot::InboxApi.list_all_inboxes(
        account_token: @account_token,
        account_id: @account_id
      )

      return {} unless response.success?

      payload = response["payload"] || []
      payload.find { |ibx| ibx.dig("name") == @instance_name }
    end
  end
end
