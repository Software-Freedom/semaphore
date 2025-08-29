class Evolution::SendMessageJob < ApplicationJob
  queue_as :default

  sidekiq_options(
    lock: :until_executed,
    lock_ttl: 10.seconds,
    unique_args: ->(args) { args[0] }
  )

  def perform(lock_key, id)
    message = Chatwoot::Message.find_by_id(id)

    return unless message
    return if message.delivery? || message.sent?

    instance = message.evolution_instance_id
    number = message.evolution_chat_id
    payload = message.payload
    text = if payload[:content]
      payload[:content]
        .gsub(/(?<!\*)\*((?!\s)([^\n*]+?)(?<!\s))\*(?!\*)/, '_\1_')   # Substitui * por _
        .gsub(/\*{2}((?!\s)([^\n*]+?)(?<!\s))\*{2}/, '*\1*')          # Substitui ** por *
        .gsub(/~{2}((?!\s)([^\n*]+?)(?<!\s))~{2}/, '~\1~')             # Substitui ~~ por ~
        .gsub(/(?<!`)`((?!\s)([^`*]+?)(?<!\s))`(?!`)/, '```\1```')    # Substitui ` por ```
    else
      payload[:content]
    end

    response = Evolution::SendMessageApi.send_plain_text(
      instance: instance,
      number: number,
      text: text
    )

    remote_id = response.parsed_response.with_indifferent_access.dig(:key, :id)

    if remote_id.present?
      message.update(sent_at: DateTime.current, evolution_remote_id: remote_id)
    end

    Evolution::RetryMessageJob.set(wait: 1.minute).perform_later(lock_key, id)
  end
end
