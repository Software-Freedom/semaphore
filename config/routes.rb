
require "sidekiq/web"

Rails.application.routes.draw do
  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_sidekiq_session"
  mount Sidekiq::Web => "/sidekiq"

  get "up" => "rails/health#show", as: :rails_health_check

  resources :chatwoot, only: [] do
    collection do
      post "/webhook/:evolution_instance_id", to: "chatwoot#webhook"
    end
  end

  resources :evolution, only: [] do
    collection do
      post "/:account_id/:account_token/connection-update", to: "evolution#connection_update"
      post "/:account_id/:account_token/contacts-update", to: "evolution#contacts_update"
      post "/:account_id/:account_token/messages-delete", to: "evolution#messages_delete"
      post "/:account_id/:account_token/messages-set", to: "evolution#messages_set"
      post "/:account_id/:account_token/messages-update", to: "evolution#messages_update"
      post "/:account_id/:account_token/messages-upsert", to: "evolution#messages_upsert"
      post "/:account_id/:account_token/send-message", to: "evolution#send_message"
    end
  end
end
