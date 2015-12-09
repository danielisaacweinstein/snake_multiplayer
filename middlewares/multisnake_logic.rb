module Multisnake
  class MultisnakeGame
    attr_accessor :center, :size, :key_code, :BLOCK_SIZE

    def initialize()
      @SCREEN_HEIGHT = 310
      @SCREEN_WIDTH = 310
      @BLOCK_SIZE = 10
      @size = {:x => @SCREEN_WIDTH, :y => @SCREEN_HEIGHT}
      @center = {:x => @size[:x] / 2, :y => @size[:y] / 2}

      @bodies = []
      # @bodies << HeadBlock.new(self)
      add_food
    end

    def add_head(client_id)
      @bodies << HeadBlock.new(self, client_id)
    end

    def add_food
      add_body(FoodBlock.new(self))
    end

    def add_body(body)
      @bodies << body
    end

    # In the JavaScript version, we ultimately got keyboard state
    # from the Keyboarder object that was created on the headblock.
    # For now, we need to get the updates from the client, and we
    # get information from the client via the websocket connection
    # which speaks to the server. Passing it through tick. Not sure
    # if this is an unwise design choice.
    def tick(key_code, client_id)
      @key_code = key_code

      update(client_id)
      get_state
    end

    def update(client_id)
      @bodies.each do |body|
        if body.class.method_defined?(:update) and body.client_id == client_id
          body.update
        end
      end

      # binding.pry
      report_collisions(@bodies)
    end

    def get_state
      mockup_data = {}
      mockup_data[:board] = {:size => {:width => 310, :height => 310}}

      snakes = []
      @bodies.each do |body|
        snake_object = {}
        snake_object[:headblock] = body.get_object
        snake_object[:bodyblocks] = []
        snakes << snake_object
      end

      mockup_data[:snakes] = snakes
      mockup_data
    end

    def random_square
      rand_generator = Random.new()

      {:x => (@size[:x] / @BLOCK_SIZE * rand_generator.rand).floor * @BLOCK_SIZE + @BLOCK_SIZE / 2,
       :y => (@size[:y] / @BLOCK_SIZE * rand_generator.rand).floor * @BLOCK_SIZE + @BLOCK_SIZE / 2}
    end

    def colliding?(b1, b2)
      !(b1.eql?(b2) or
          b1[:center][:x] + b1[:size][:x] / 2 <= b2[:center][:x] - b2[:size][:x] / 2 or
          b1[:center][:y] + b1[:size][:y] / 2 <= b2[:center][:y] - b2[:size][:y] / 2 or
          b1[:center][:x] - b1[:size][:x] / 2 >= b2[:center][:x] + b2[:size][:x] / 2 or
          b1[:center][:y] - b1[:size][:y] / 2 >= b2[:center][:y] + b2[:size][:y] / 2
        )
    end

    def square_free?(new_center)
      collision = @bodies.select do |body|
        colliding?(body.get_object, {:center => new_center,
                             :size => {:x => @BLOCK_SIZE,
                                       :y => @BLOCK_SIZE}})
      end

      return collision.length == 0
    end

    def remove_body(body)
      @bodies.delete(body)
    end

    def report_collisions(bodies)
      collisions = []

      for i in 0..(bodies.length - 1) do
        for j in (i + 1)..(bodies.length - 1) do
          collisions << [bodies[i], bodies[j]] if colliding?(bodies[i].get_object, bodies[j].get_object)
        end
      end

      collisions.each_with_index do |collision, i|
        if collisions[i][0].class.method_defined?(:collision)
          collisions[i][0].collision(collisions[i][1])
        end

        if collisions[i][1].class.method_defined?(:collision)
          collisions[i][1].collision(collisions[i][0])
        end
      end
    end
  end

  class FoodBlock
    attr_accessor :center, :size

    def initialize(game)
      @game = game
      @center

      while !defined?(@center) do
        random_center = game.random_square
        @center = random_center if game.square_free?(random_center)
      end

      @size = {:x => game.BLOCK_SIZE, :y => game.BLOCK_SIZE}

    end

    def collision(other_body)
      @game.remove_body(self) if other_body.class.name.include?("HeadBlock")
    end

    def get_object
      {:center => @center, :color => "green", :size => {:x => 10, :y => 10}}
    end
  end

  class HeadBlock
    attr_accessor :center, :size, :color, :client_id

    def initialize(game, client_id)
      @client_id = client_id
      @game = game
      @BLOCK_SIZE = @game.BLOCK_SIZE

      while !defined?(@center) do
        random_center = game.random_square
        @center = random_center if game.square_free?(random_center)
      end

      # @center = {:x => @game.center[:x], :y => @game.center[:y]}
      @direction = {:x => 1, :y => 0}
      @size = {:x => @BLOCK_SIZE, :y => @BLOCK_SIZE}
      @blocks = []

      @last_move = Time.now
      @add_block = false
    end

    def update
      handle_keyboard(@game.key_code)

      now = Time.now
      if (now > @last_move)
        move
        @last_move = now
      end
    end

    def collision(other_body)
      # if other_body.class.name == 
      # # puts "HeadBlock collision ==> death"
      # # puts "EATEN" if other_body.class.name == "FoodBlock"
      eat
    end

    def eat
      @add_block = true
      @game.add_food
    end

    def handle_keyboard(key_code)
      @KEYS = {:LEFT => 37, :RIGHT => 39, :UP => 38, :DOWN => 40}

      if key_code == @KEYS[:LEFT]
        @direction[:x] = -1
        @direction[:y] = 0
      elsif key_code == @KEYS[:RIGHT]
        @direction[:x] = 1
        @direction[:y] = 0
      elsif key_code == @KEYS[:UP]
        @direction[:y] = -1
        @direction[:x] = 0
      elsif key_code == @KEYS[:DOWN]
        @direction[:y] = 1
        @direction[:x] = 0
      end
    end

    def move
      prev_block_center = {:x => @center[:x], :y => @center[:y]}
      @center[:x] += @direction[:x] * @BLOCK_SIZE
      @center[:y] += @direction[:y] * @BLOCK_SIZE

      if @add_block == true
        block = BodyBlock.new(@game, prev_block_center)
        @game.add_body(block)
        @blocks << block
        @add_block = false
      end

      @blocks.each_with_index do |block, i|
        old_center = @blocks[i].center
        @blocks[i].center = {:x => prev_block_center[:x], :y => prev_block_center[:y]}
        prev_block_center = old_center
      end

    end

    def get_object
      {:center => @center, :color => "red", :size => {:x => 10, :y => 10}}
    end
  end

  class BodyBlock
    attr_accessor :center, :size

    def initialize(game, center)
      @game = game
      @center = center
      @size = game.BLOCK_SIZE
    end

    def get_object
      {:center => @center, :color => "black", :size => {:x => @game.BLOCK_SIZE, :y => @game.BLOCK_SIZE}}
    end
  end
end