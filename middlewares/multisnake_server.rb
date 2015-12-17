require_relative 'multisnake_logic'
require 'faye/websocket'
require 'thread'
require 'json'
require 'erb'
require 'pry'

# Encapsulates WebSocket logic and Rack middleware.
module Multisnake
  class MultisnakeServer
    KEEPALIVE_TIME = 15 # in seconds

    def initialize(app)
      @clients = []
      @moves   = {}
      @app     = app
      @player_count = 2
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })

        # Initiate game when we've established two connections.
        ws.on :open do |event|
          @clients << ws
          start_game if @clients.length == @player_count
        end

        # On message, update move hash for latest client actions.
        ws.on :message do |event|
          data = eval(event.data)

          key_code = data[:keycode] if data.key?(:keycode)
          room = data[:room] if data.key?(:room)

          binding.pry
          puts data
          @moves[ws.object_id.to_s.to_sym] = keycode

        end

        # On close, delete the WebSocket from list of clients.
        ws.on :close do |event|
          @clients.delete(ws)
          ws = nil
        end

        # Instruct game to create two players and initiate game loop.
        def start_game
          client_IDs = []

          @clients.each_with_index { |client, index| client_IDs << @clients[index].object_id }
          @game = MultisnakeGame.new(client_IDs)

          game_interval = 0.3
          @loop = EM.add_periodic_timer(game_interval) do
            state = @game.tick(@moves)
            json_game_state = JSON.generate(state)
            @clients.each {|client| client.send(json_game_state)}

            # Game ends when players lose or client loses connection.
            if state[:game_over] or @clients.length < @player_count
              EM.cancel_timer
            end
          end
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
      end
    end
  end
end
