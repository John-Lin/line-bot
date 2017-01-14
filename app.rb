require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'
require 'forecast_io'

configure :development, :test do
  require 'config_env'
  ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
  ForecastIO.api_key = ENV["FORECASTIO_APIKEY"]
end

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

get '/ping' do
  "PONG"
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)

  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        message = {
          type: 'text',
          text: event.message['text']
        }

        # Echo methods
        # reply event, message
        # client.reply_message(event['replyToken'], message)

        # Weather
        f = ForecastIO.forecast(25.03, 121.30, params: { units: 'si', lang: 'zh-tw' })
        reply event, textmsg(f.daily.summary)

      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        reply event, textmsg("謝謝分享，但我現在還看不懂圖片與影片呢。")
      end
    end
  }

  "OK"
end

def textmsg text
  if text.is_a? String
    return {
      type: 'text',
      text: text
    }
  end

  # it is probably already wrapped. Skip wrapping with type.
  return text
end

def reply event, data
  client.reply_message event['replyToken'], data
  p data
end
