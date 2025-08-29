require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MeuProjetoApi
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true
    config.active_job.queue_adapter = :sidekiq

    config.autoload_paths << Rails.root.join('app/services')
    config.eager_load_paths << Rails.root.join('app/services')

    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_CACHE_URL"),
      namespace: "cache"
    }
  end
end
