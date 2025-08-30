module Chatwoot
  class FindOrCreateConversationService
    def self.call(**args)
      new(**args).call
    end

    def initialize(account_token:, account_id:, remote_jid:, instance_name:, contact_name:, avatar_url: "")
      @account_token = account_token
      @account_id = account_id
      @remote_jid = remote_jid
      @instance_name = instance_name
      @contact_name = contact_name
      @avatar_url = avatar_url
    end

    def call
      conversation = find
      conversation = create unless conversation

      conversation.to_h.with_indifferent_access
    end

    private

    def find
      response = Chatwoot::ConversationApi.conversations_filter(
        account_token: @account_token,
        account_id: @account_id
      )

      payload = response["payload"] || []

      conversation = payload.find do |conv|
        conv.dig("meta", "sender", "identifier") == @remote_jid
      end

      conversation
    end

    def create
      inbox = Chatwoot::FindInboxService.call(
        account_token: @account_token,
        account_id: @account_id,
        instance_name: @instance_name
      )

      contact = Chatwoot::FindOrCreateContact.call(
        account_token: @account_token,
        account_id: @account_id,
        inbox_id: inbox["id"],
        name: @contact_name,
        email: "",
        avatar_url: @avatar_url,
        identifier: @remote_jid
      )

      response = Chatwoot::ConversationApi.create_new_conversation(
        account_token: @account_token,
        account_id: @account_id,
        inbox_id: inbox["id"],
        contact_id: contact["id"],
      )

      unless response.success?
        details = "Código: #{response.code}\n"
        message_info = "Corpo: #{response.body}\n"
        content = "#{details}#{message_info}"

        Discord::MessageApi.send_message(content: content)
        return
      end
      
      response
    end
  end
end
