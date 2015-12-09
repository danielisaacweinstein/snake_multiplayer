require_relative 'multisnake_logic'
require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'
require 'erb'
require 'pry'

# Encapsulates WebSocket logic and Rack middleware.
module Multisnake
  class MultisnakeServer
    KEEPALIVE_TIME = 15 # in seconds
    CHANNEL        = "chat-demo"

    def initialize(app)
      @app     = app
      @clients = []
      @game = MultisnakeGame.new()
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        # ping sends a message every X number of seconts to keep connection alive.
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws
          start_game if @clients.length >= 2
        end

        ws.on :message do |event|
          #if event.data.type
          p [:message, event.data]

          # binding.pry
          key_code = event.data.to_i
          state = @game.tick(key_code, ws.object_id)
          json_game_state = JSON.generate(state)
          ws.send(json_game_state)
        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          ws = nil
        end

        def start_game
          @clients.each { |client|
            @game.add_head(client.object_id)
          }
          loop = EM.add_periodic_timer(0.2) {
            @clients.each { |client|
              state = @game.tick(45, client.object_id)
              json_game_state = JSON.generate(state)
              client.send(json_game_state)
            }
          }
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
      end
    end
  end
end
