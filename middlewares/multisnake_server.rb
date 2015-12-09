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
      @game      = MultisnakeGame.new()
      @last_tick = Time.now
      @app       = app
      @clients   = []
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws
          start_game if @clients.length >= 2
        end

        ws.on :message do |event|
          p [:message, event.data]

          if Time.now > @last_tick + (0.2).to_f
            key_code = event.data.to_i
            @game.tick(key_code, ws.object_id)
            @last_tick = Time.now
          end
        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          ws = nil
        end

        def start_game
          @clients.each { |client| @game.add_head(client.object_id) }
          
          @loop = EM.add_periodic_timer(0.2) do
            @clients.each do |client|
              state = @game.tick(45, client.object_id)
              json_game_state = JSON.generate(state)
              client.send(json_game_state)

              if state[:game_over]
                binding.pry
                EM.cancel_timer
                # close connection
              end

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
