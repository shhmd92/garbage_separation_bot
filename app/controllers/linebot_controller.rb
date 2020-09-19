# frozen_string_literal: true

class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery except: [:callback]

  BURNABLE = %W[\u751F\u3054\u307F \u7D19\u3054\u307F \u30B4\u30E0\u88FD\u54C1\u985E \u30D7\u30E9\u30B9\u30C1\u30C3\u30AF\u985E \u9769\u88FD\u54C1 \u98DF\u7528\u6CB9 \u8863\u985E].freeze
  NON_BURNABLE = %W[\u91D1\u5C5E\u985E \u30AC\u30E9\u30B9\u985E \u9676\u78C1\u5668\u985E 30\u30BB\u30F3\u30C1\u672A\u6E80\u306E\u5BB6\u96FB\u88FD\u54C1].freeze
  RECYCLABLE = %W[\u65B0\u805E \u96D1\u8A8C \u6BB5\u30DC\u30FC\u30EB \u3073\u3093 \u7F36 \u30DA\u30C3\u30C8\u30DC\u30C8\u30EB \u7D19\u30D1\u30C3\u30AF \u7D19\u7BB1 \u7D19\u888B OA\u7528\u7D19].freeze

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    head :bad_request unless client.validate_signature(body, signature)

    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          client.reply_message(event['replyToken'], create_message(event))
        end
      end
    end

    head :ok
  end

  private

  def create_message(event)
    seatch_text = event.message['text']
    if BURNABLE.select { |e| e =~ /.*#{seatch_text}.*/ }
      '可燃ゴミ'
    elsif NON_BURNABLE.select { |e| e =~ /.*#{seatch_text}.*/ }
      '不燃ゴミ'
    elsif RECYCLABLE.select { |e| e =~ /.*#{seatch_text}.*/ }
      '資源ゴミ'
    else
      '不明'
    end
  end
end
