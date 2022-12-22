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
            text = regist_cost(strings[2], strings[3].to_i, event['source']['userId'])
          when '確認'
          when '精算'
          else
            text = '入力形式が不正です。内容を確認して再度入力してください'
          end

          message = {
            type: 'text',
            text: text
          }
          client.reply_message(event['replyToken'], message)
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

  def regist_cost(name, cost, line_user_id)
    return "登録に失敗しました。\n費用の形式が不正です。正しく数値を入力してください。" if cost <= 0

    expense = Expense.new(name: name, cost: cost, paid: false, line_user_id: line_user_id)

    if expense.save
      "登録に成功しました。\nID:#{expense.id}\n#{expense.name}\n#{expense.cost.to_formatted_s(:delimited)}円"
    else
      '登録に失敗しました。'
    end
  end
end
