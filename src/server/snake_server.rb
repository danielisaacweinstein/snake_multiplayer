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
      @game = MultisnakeGame.new()
    end

    ws.on(:message) do |msg|
      # ws.send(msg.data.reverse)  # Reverse and reply

      # body = {:HeadBlock => {:position => {:x => 5, :y => 5},
      #                        :color => "red"}
      #        }

      # puts JSON.generate(body)
      # ws.send(JSON.generate(body))

      # ws.send(@game.get_state)
      json_message = JSON.generate(@game.get_state)
      ws.send(json_message)

      # ws.send(@game.get_state.to_s)
      # puts msg.data
    end

    ws.on(:close) do |event|
      puts 'On Close'
    end

    ws.rack_response
  else
    # erb :index
  end
end
