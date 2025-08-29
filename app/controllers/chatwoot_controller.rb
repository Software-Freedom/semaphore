class ChatwootController < ApplicationController
  def webhook
    evolution_instance_id = params[:evolution_instance_id]
    event = params[:event]
    message_type = params[:message_type]

    if message_type == Chatwoot::Message::MESSAGE_TYPE[:INCOMING]
      render json: {}, status: :ok
      return
    end

    if event == Chatwoot::Message::EVENTS[:MESSAGE_CREATED]
      Chatwoot::Message.create(
        evolution_instance_id: evolution_instance_id,
        event: event,
        payload: params.to_unsafe_h.except(:controller, :action)
      )
    end

    render json: {}, status: :ok
  end
end
