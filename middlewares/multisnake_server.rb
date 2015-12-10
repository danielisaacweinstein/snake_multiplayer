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

    def initialize(app)
      @game       = MultisnakeGame.new()
      @last_moves = {}
      @app        = app
      @clients    = []
      @number_of_times_started = 0
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws
          @last_moves[ws.object_id.to_s.to_sym]
          if @clients.length >= 2 and @number_of_times_started == 0
            start_game
            @number_of_times_started += 1
          end
        end

        ws.on :message do |event|
          p [:message, event.data]

          key_code = event.data.to_i
          @last_moves[ws.object_id.to_s.to_sym] = key_code
        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]

          @clients.delete(ws)
          ws = nil
        end

        def start_game
          @clients.each { |client| @game.add_head(client.object_id) }

          @loop = EM.add_periodic_timer(0.2) do
            state = @game.tick(@last_moves)
            json_game_state = JSON.generate(state)
            @clients.each {|client| client.send(json_game_state)}
            
            if state[:game_over] or @clients.length < 2
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
