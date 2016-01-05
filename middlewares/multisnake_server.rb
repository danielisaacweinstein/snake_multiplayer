require_relative 'multisnake_logic'
require 'faye/websocket'
require 'thread'
require 'json'
require 'erb'
require 'pry'

# Encapsulates WebSocket logic and Rack middleware.
module Multisnake
  class MultisnakeServer
    KEEPALIVE_TIME    = 15     # In seconds
    GAME_INTERVAL     = 0.3    # In seconds
    DEFAULT_DIRECTION = 38     # Up
    
    def initialize(app)
      @rooms          = []
      @app            = app
      @player_count   = 1
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })

        ws.on :open do |event|
          puts "Established connection with client: " + ws.object_id.to_s
        end

        ws.on :message do |event|
          data = eval(event.data)
          handle_websocket_message(ws, data)
        end

        ws.on :close do |event|
          puts "Closing connection with client: " + ws.object_id.to_s

          client = find_client(ws)
          room = @rooms.find {|r| r[:clients].include?(client)}
          close_room(room)

          ws = nil
        end

        def find_client(websocket)
          all_clients = @rooms.flat_map {|r| r[:clients]}
          all_clients.find {|c| c[:client] == websocket }
        end

        # Client sends room name through event_data in message after establishing
        # connection, and only sends keycodes through event_data after that time.
        def handle_websocket_message(websocket, event_data)
          if event_data.key?(:room)
            room_name = event_data[:room]
            room = get_or_create_room(room_name)
            room[:clients] << create_client(websocket)
            run_game(room) if (room[:clients].length > @player_count and !room[:game])
          elsif event_data.key?(:keycode)
            move = event_data[:keycode]
            client = find_client(websocket)
            client[:move] = move
          end
        end

        def run_game(room)
          # Initiate new game using client_ids from the specific room.
          client_IDs = room[:clients].flat_map {|c| c[:client_id]}
          room[:game] = MultisnakeGame.new(client_IDs)

          # Attach game loop to the room to initiate logic.
          room[:loop] = EM.add_periodic_timer(GAME_INTERVAL) do
            moves = {}
            room[:clients].each {|c| moves[c[:client_id].to_sym] = c[:move] }
            state = room[:game].tick(moves)
            json_game_state = JSON.generate(state)
            room[:clients].each {|client| client[:client].send(json_game_state)}

            close_room(room) if state[:game_over]
          end
        end

        def get_or_create_room(room_name)
          room = @rooms.find {|r| r[:name] == room_name}

          if !room
            room = { :name    => room_name,
                     :clients => [] }
            @rooms << room
          end

          return room
        end

        def create_client(websocket)
          { :client    => websocket,
            :client_id => websocket.object_id.to_s,
            :move      => DEFAULT_DIRECTION }
        end

        def close_room(room)
          room[:loop].cancel                          # Cancel timer
          @rooms.delete(room)                         # Delete room
          room[:clients].each {|c| c[:client].close}  # Close socket
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
      end
    end
  end
end
