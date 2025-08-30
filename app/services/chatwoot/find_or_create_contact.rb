module Chatwoot
  class FindOrCreateContact
    def self.call(**args)
      new(**args).call
    end

    def initialize(account_token:, account_id:, inbox_id:, name:, avatar_url:, identifier:, email: "")
      @account_token = account_token
      @account_id = account_id
      @inbox_id = inbox_id
      @name = name
      @email = email
      @avatar_url = avatar_url
      @identifier = identifier
      @phone_number = "+#{identifier.to_s.gsub(/\D/, '')}"
    end

    def call
      contact = find
      contact = create unless contact

      contact.to_h.with_indifferent_access
    end

    private

    def find
      response = Chatwoot::ContactApi.list_contacts(
        account_token: @account_token,
        account_id: @account_id
      )

      payload = response["payload"] || []

      contact = payload.find do |cot|
        cot.dig("identifier") == @identifier ||
        cot.dig("phone_number") == @phone_number
      end

      return unless contact.present?

      contact
    end

    def create
      response = Chatwoot::ContactApi.create_contact(
        account_token: @account_token,
        account_id: @account_id,
        inbox_id: @inbox_id,
        name: @name,
        email: @email,
        phone_number: @phone_number,
        avatar_url: @avatar_url,
        identifier: @identifier
      )

      return unless response.success?

      response
    end
  end
end