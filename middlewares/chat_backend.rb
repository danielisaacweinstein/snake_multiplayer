require_relative 'multisnake'
require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'
require 'erb'
require 'pry'

# Encapsulates WebSocket logic and Rack middleware.
module Multisnake
  class ChatBackend
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
        end

        ws.on :message do |event|
          p [:message, event.data]

          # binding.pry
          key_code = event.data.to_i
          state = @game.tick(key_code)
          json_game_state = JSON.generate(state)
          ws.send(json_game_state)
        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
      end
    end
  end
end
