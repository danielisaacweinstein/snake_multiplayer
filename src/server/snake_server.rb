require_relative 'multisnake'
require 'sinatra/base'
require 'json'
require 'bundler'
Bundler.require

class ServerClass < Sinatra::Base
  def initialize
    Faye::WebSocket.load_adapter('thin')
    # @game
    puts "LINE 11"
  end

  puts "LINE 14"
  
  get '/' do
    if Faye::WebSocket.websocket?(request.env)
      ws = Faye::WebSocket.new(request.env)

      ws.on(:open) do |event|
        # puts @game
        # if !defined?(@game)
          @game = MultisnakeGame.new()
        # else
        #   puts "ALREADY GAME"
        # end
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

  puts "LINE 46"
  run! if app_file == $0
  puts "LINE 47"
end

ServerClass.new