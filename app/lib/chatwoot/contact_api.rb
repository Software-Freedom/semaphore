
module Chatwoot
  class ContactApi
    include HTTParty
    base_uri ENV["CHATWOOT_URL"]

    class << self
      def list_contacts(account_token:,account_id:)
        url = "/accounts/#{account_id}/contacts"

        options = {
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{account_token}",
            "api_access_token" => account_token
          }
        }

        get(url, options)
      end

      def create_contact(
        account_token:,
        account_id:,
        inbox_id:,
        name:,
        email:,
        phone_number:,
        avatar_url:,
        identifier:,
        blocked: false,
        additional_attributes: {},
        custom_attributes: {}
      )
        url = "/accounts/#{account_id}/contacts"

        default_additional_attributes = {
          type: "customer"
        }

        options = {
          headers: {
            "Content-Type" => "application/json",
            "Authorization" => "Bearer #{account_token}",
            "api_access_token" => account_token
          },
          body: {
            inbox_id: inbox_id,
            name: name,
            email: email,
            blocked: blocked,
            phone_number: phone_number,
            avatar_url: avatar_url,
            identifier: identifier,
            additional_attributes: additional_attributes.merge(additional_attributes),
            custom_attributes: custom_attributes
          }.to_json
        }

        post(url, options)
      end
    end
  end
end