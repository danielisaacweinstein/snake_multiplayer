require_relative 'multisnake'
require 'json'
require 'bundler'
Bundler.require

Faye::WebSocket.load_adapter('thin')

get '/' do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env)

    ws.on(:open) do |event|
      # puts 'On Open'
    end

    ws.on(:message) do |msg|
      # ws.send(msg.data.reverse)  # Reverse and reply

      # body = {:HeadBlock => {:position => {:x => 5, :y => 5},
      #                        :color => "red"}
      #        }

      # puts JSON.generate(body)
      # ws.send(JSON.generate(body))

      ws.send(msg.data.reverse)  # Reverse and reply
      puts msg.data

    end

    ws.on(:close) do |event|
      puts 'On Close'
    end

    ws.rack_response
  else
    # erb :index
  end
end
