# frozen_string_literal: true

class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery except: [:callback]

  BURNABLE = %w[
    生ごみ
    紙ごみ
    ゴム製品類
    プラスチック類
    革製品
    食用油
    衣類
  ].freeze
  NON_BURNABLE = %w[
    金属類
    ガラス類
    陶磁器類
    30センチ未満の家電製品
  ].freeze
  RECYCLABLE = %w[
    新聞
    雑誌
    段ボール
    びん
    缶
    ペットボトル
    紙パック
    紙箱
    紙袋
    OA用紙
  ].freeze

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
    if BURNABLE.include?(seatch_text)
      '可燃ゴミ'
    elsif NON_BURNABLE.include?(seatch_text)
      '不燃ゴミ'
    elsif RECYCLABLE.include?(seatch_text)
      '資源ゴミ'
    else
      '不明'
    end
  end
end
