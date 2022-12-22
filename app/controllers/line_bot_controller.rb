class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end

    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          strings = event.message['text'].split(/\R/)
          return unless strings[0] == '@家計管理' || strings[0] == '＠家計管理'

          case strings[1]
          when '登録'
          when '確認'
          when '精算'
          else
            message = {
              type: 'text',
              text: '書式が違います。内容を確認して再度入力してください'
            }
            client.reply_message(event['replyToken'], message)
          end
        end
      end
    end

    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = Rails.application.credentials.line[:channel_secret]
      config.channel_token = Rails.application.credentials.line[:channel_token]
    }
  end
end
