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
          line_user_id = event['source']['userId']

          case strings[0]
          when '登録'
            text = regist_cost(strings[1], strings[2].to_i, line_user_id)
          when '確認'
            text = list_expenses(line_user_id)
          when '精算'
            text = pay_expenses(strings[1], line_user_id)
          else
            text = "😄使い方😄\n以下の書式に従ってメッセージを送信してください。\n\n✏️費用の登録✏️\n登録\n費用の名前\n金額\n\n🔍費用の確認🔍\n確認\n\n💰費用の精算💰\n精算\n精算したいID（,区切りで複数可能）\n\n使い方を再度見るには、「ヘルプ」と送信してください。"
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
  
  def list_expenses(line_user_id)
    expenses = Expense.where(line_user_id: line_user_id, paid: false)

    text = "未精算の一覧を出力します。\n"
    expenses.each do |expense|
      text << "#{expense.id}|#{expense.name}|#{expense.cost.to_formatted_s(:delimited)}円\n"
    end

    text << "=================\n"
    text << "合計 #{expenses.sum(:cost).to_formatted_s(:delimited)}円"
  end
  
  def pay_expenses(id, line_user_id)
    return 'IDの形式が不正です。半角数字で入力してください。' if id.blank?
    
    ids = id.chomp.split(",").map do |n|
      return 'IDの形式が不正です。半角数字で入力してください。' if n.to_i == 0
      n.to_i
    end
    
    expenses = Expense.where(line_user_id: line_user_id, id: ids, paid: false)
    
    return '指定されたIDは、既に精算が済んでいます。' if expenses.blank?
    
    text = "以下の費用を精算しました。\n"
    expenses.each do |expense|
      text << "#{expense.id}|#{expense.name}|#{expense.cost.to_formatted_s(:delimited)}円\n"
    end

    text << "=================\n"
    text << "合計 #{expenses.sum(:cost).to_formatted_s(:delimited)}円"

    expenses.update_all(paid: true)

    text
  end
end
