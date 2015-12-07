require_relative 'multisnake'
require 'sinatra/base'
require 'json'
require 'bundler'
Bundler.require

Faye::WebSocket.load_adapter('thin')

get '/' do
  if Faye::WebSocket.websocket?(request.env)
    ws = Faye::WebSocket.new(request.env)

    ws.on(:open) do |event|
      # check what's already running
      @game = MultisnakeGame.new()
    end

    ws.on(:message) do |msg|
      key_code = msg.data.to_i

      state = @game.tick(key_code)
      json_game_state = JSON.generate(state)
      # puts json_game_state
      ws.send(json_game_state)
    end

    ws.on(:close) do |event|
      puts 'On Close'
    end

    ws.rack_response
  else
    # erb :index
  end
end
