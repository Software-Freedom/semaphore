class EvolutionController < ApplicationController
  # {"event"=>"connection.update", "instance"=>"wl_store_brasil_1", "data"=>{"instance"=>"wl_store_brasil_1", "state"=>"connecting", "statusReason"=>200}, "destination"=>"https://70f88d4101fe.ngrok-free.app/evolution", "date_time"=>"2025-08-27T15:23:19.703Z", "server_url"=>"http://localhost:8080", "apikey"=>"B552ED8476DD-49CC-B743-01A0AEAE1EB5", "controller"=>"evolution", "action"=>"connection_update", "evolution"=>{"event"=>"connection.update", "instance"=>"wl_store_brasil_1", "data"=>{"instance"=>"wl_store_brasil_1", "state"=>"connecting", "statusReason"=>200}, "destination"=>"https://70f88d4101fe.ngrok-free.app/evolution", "date_time"=>"2025-08-27T15:23:19.703Z", "server_url"=>"http://localhost:8080", "apikey"=>"B552ED8476DD-49CC-B743-01A0AEAE1EB5"}}
  def connection_update
    render json: {}, status: :ok
  end

  def contacts_update
    render json: {}, status: :ok
  end

  # {"event"=>"messages.delete", "instance"=>"wl_store_brasil_1", "data"=>#<ActionController::Parameters {"remoteJid"=>"556295330566@s.whatsapp.net", "fromMe"=>false, "id"=>"3A7DD0E0A7F5D3F088AB", "senderLid"=>"279903287165150@lid"} permitted: false>, "destination"=>"https://23156f91201c.ngrok-free.app/evolution/1/4WNYQomTkLD4ubmzkZzq6Lmn", "date_time"=>"2025-08-28T09:49:00.278Z", "sender"=>"554789079187@s.whatsapp.net", "server_url"=>"http://localhost:8080", "apikey"=>"B552ED8476DD-49CC-B743-01A0AEAE1EB5", "controller"=>"evolution", "action"=>"messages_delete", "account_id"=>"1", "account_token"=>"4WNYQomTkLD4ubmzkZzq6Lmn", "evolution"=>{"event"=>"messages.delete", "instance"=>"wl_store_brasil_1", "data"=>{"remoteJid"=>"556295330566@s.whatsapp.net", "fromMe"=>false, "id"=>"3A7DD0E0A7F5D3F088AB", "senderLid"=>"279903287165150@lid"}, "destination"=>"https://23156f91201c.ngrok-free.app/evolution/1/4WNYQomTkLD4ubmzkZzq6Lmn", "date_time"=>"2025-08-28T09:49:00.278Z", "sender"=>"554789079187@s.whatsapp.net", "server_url"=>"http://localhost:8080", "apikey"=>"B552ED8476DD-49CC-B743-01A0AEAE1EB5"}}
  def messages_delete
    account_id = params[:account_id]
    account_token = params[:account_token]
    remote_id = params[:data].dig("id")

    unless remote_id
      render json: { message: "SEM ID DE MENSAGEM id: #{remote_id}"}, status: :ok
      return
    end

    message = Evolution::Message.find_by(evolution_remote_id: remote_id)

    unless message
      render json: { message: "MENSAGEM NÃO ENCONTRADA id: #{remote_id}"}, status: :ok
      return
    end
    
    conversation_id = message.chatwoot_conversation_id
    message_id = message.chatwoot_message_id
    response = Chatwoot::MessageApi.delete_message(account_token: account_token, 
                                                  account_id: account_id, 
                                                  conversation_id: conversation_id,
                                                  message_id: message_id)

    message.update(deleted: response.success?)
    render json: {}, status: :ok
  end

  def messages_set
    render json: {}, status: :ok
  end

  # {"event":"messages.upsert", "instance":"wl_store_brasil_1", "data":{"key":{"remoteJid":"556295330566@s.whatsapp.net", "fromMe":false, "id":"3A663B886BB1BCD537FE", "senderLid":"279903287165150@lid"}, "pushName":"Well", "status":"DELIVERY_ACK", "message":{"conversation":"op", "messageContextInfo":{"deviceListMetadata":{"senderKeyHash":"wPJ9YRzpBwKtaQ==", "senderTimestamp":"1754931659", "recipientKeyHash":"Ft4sY6bu7wx1zA==", "recipientTimestamp":"1756161502"}, "deviceListMetadataVersion":2, "messageSecret":"swWuc/5683x1BjVvDLfK/HxvvnQiTRcWpUFN4Siq/vo="}}, "messageType":"conversation", "messageTimestamp":1756319515, "instanceId":"d5f5e05a-c19c-425d-8dcb-e930c82f9ef8", "source":"ios"}, "destination":"https://70f88d4101fe.ngrok-free.app/evolution", "date_time":"2025-08-27T15:31:55.234Z", "sender":"554789079187@s.whatsapp.net", "server_url":"http://localhost:8080", "apikey":"B552ED8476DD-49CC-B743-01A0AEAE1EB5", "controller":"evolution", "action":"messages_upsert", "evolution":{"event":"messages.upsert", "instance":"wl_store_brasil_1", "data":{"key":{"remoteJid":"556295330566@s.whatsapp.net", "fromMe":false, "id":"3A663B886BB1BCD537FE", "senderLid":"279903287165150@lid"}, "pushName":"Well", "status":"DELIVERY_ACK", "message":{"conversation":"op", "messageContextInfo":{"deviceListMetadata":{"senderKeyHash":"wPJ9YRzpBwKtaQ==", "senderTimestamp":"1754931659", "recipientKeyHash":"Ft4sY6bu7wx1zA==", "recipientTimestamp":"1756161502"}, "deviceListMetadataVersion":2, "messageSecret":"swWuc/5683x1BjVvDLfK/HxvvnQiTRcWpUFN4Siq/vo="}}, "messageType":"conversation", "messageTimestamp":1756319515, "instanceId":"d5f5e05a-c19c-425d-8dcb-e930c82f9ef8", "source":"ios"}, "destination":"https://70f88d4101fe.ngrok-free.app/evolution", "date_time":"2025-08-27T15:31:55.234Z", "sender":"554789079187@s.whatsapp.net", "server_url":"http://localhost:8080", "apikey":"B552ED8476DD-49CC-B743-01A0AEAE1EB5"}}
  def messages_upsert
    message_type = params[:data].to_unsafe_h.dig(:messageType)
    instance = params[:instance]
    account_id = params[:account_id]
    account_token = params[:account_token]
    event = params[:event]
    remote_jid = params[:data].to_unsafe_h.dig(:key, :remoteJid)
    contact_name = params[:data].to_unsafe_h.dig(:pushName)

    if message_type != Evolution::Message::MESSAGE_TYPE[:CONVERSATION] && 
      message_type != Evolution::Message::MESSAGE_TYPE[:MESSAGE] &&
      message_type != Evolution::Message::MESSAGE_TYPE[:LOCATION_MESSAGE] &&
      message_type != Evolution::Message::MESSAGE_TYPE[:CONTACT_MESSAGE] &&
      message_type != Evolution::Message::MESSAGE_TYPE[:CONTACT_ARRAY_MESSAGE] &&
      message_type != Evolution::Message::MESSAGE_TYPE[:IMAGE_MESSAGE] &&
      message_type != Evolution::Message::MESSAGE_TYPE[:AUDIO_MESSAGE] &&
      message_type != Evolution::Message::MESSAGE_TYPE[:VIDEO_MESSAGE] &&
      message_type != Evolution::Message::MESSAGE_TYPE[:DOCUMENT_MESSAGE] &&
      message_type != Evolution::Message::MESSAGE_TYPE[:STICKER_MESSAGE]

      render json: { message: "Tipo de mensagem inválido #{message_type}"}, status: :ok
      return
    end

    # cache_key = "conversation-id-#{instance_name}-#{remote_jid}"
    # conversation_id = Rails.cache.read(cache_key)

    # unless conversation_id
    #   conversation = Chatwoot::FindOrCreateConversationService.call(account_token: account_token, 
    #                                                                 account_id: account_id, 
    #                                                                 remote_jid: remote_jid,
    #                                                                 instance_name: instance,
    #                                                                 contact_name: contact_name)
    #   conversation_id = conversation["id"]
    #   Rails.cache.write(cache_key, conversation_id)
    # end

    conversation = Chatwoot::FindOrCreateConversationService.call(account_token: account_token, 
                                                                account_id: account_id, 
                                                                remote_jid: remote_jid,
                                                                instance_name: instance,
                                                                contact_name: contact_name)

    conversation_id = conversation["id"]
    Evolution::Message.create!(
      event: event,
      evolution_instance_id: instance,
      chatwoot_account_id: account_id,
      chatwoot_account_token: account_token,
      chatwoot_conversation_id: conversation_id,
      payload: params.to_unsafe_h.except(:controller, :action)
    )

    render json: {}, status: :ok
  end

  def messages_update
    event = params[:event]
    data = params[:data].to_unsafe_h.with_indifferent_access
    remote_id = data.dig(:keyId)
    status = data.dig(:status)

    message = Chatwoot::Message.find_by(evolution_remote_id: remote_id)

    unless message
      render json: {}, status: :ok
      return
    end

    message.update(server: true, delivery: true, read: true) if status == "READ"
    message.update(server: true, delivery: true)  if status == "DELIVERY_ACK"
    message.update(server: true,) if status == "SERVER_ACK"

    render json: {}, status: :ok
  end

  def send_message
    event = params[:event]
    data = params[:data].to_unsafe_h.with_indifferent_access
    remote_id = data.dig(:key, :id)
    message = Chatwoot::Message.find_by(evolution_remote_id: remote_id)

    unless message
      render json: {}, status: :ok
      return
    end

    message.update(sent: true, pending: true)

    render json: {}, status: :ok
  end
end
