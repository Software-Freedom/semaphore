Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_QUEUE_URL") }

  config.error_handlers << proc do |ex, ctx_hash|
    Discord::MessageApi.send_message(
      content: "❌ Falha no job *#{ctx_hash[:job]['class']}*\n" \
               "Erro: `#{ex.message}`\n" \
               "Args: ```#{ctx_hash[:job]['args'].inspect}```"
    )
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_QUEUE_URL") }
end
