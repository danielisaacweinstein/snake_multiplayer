module Multisnake
  class MultisnakeGame
    attr_accessor :BLOCK_SIZE, :size, :last_moves

    def initialize(client_ids)
      @SCREEN_HEIGHT = 500
      @SCREEN_WIDTH = 500
      @BLOCK_SIZE = 10

      @size   = {:x => @SCREEN_WIDTH,
                 :y => @SCREEN_HEIGHT}
      @center = {:x => @size[:x] / 2,
                 :y => @size[:y] / 2}

      @client_ids = client_ids
      @game_over = false
      @score = 0
      @bodies = []

      arrange_new_board
    end

    def arrange_new_board
      add_body(FoodBlock.new(self))
      @client_ids.each_with_index do |client, index|
        new_snake = HeadBlock.new(self, client)

        if index == 0
          new_snake.set_color("#6E0053")
        else index == 1
          new_snake.set_color("#0A0A69")
        end

        add_body(new_snake)
      end
    end

    def add_food
      add_body(FoodBlock.new(self))
    end

    def add_body(body)
      @bodies << body
    end

    def tick(last_moves)
      @last_moves = last_moves
      update
      get_state
    end

    def increase_score
      @score += 1
    end

    def die
      @bodies = []
      @game_over = true
    end

    def update
      @bodies.each do |body|
        if body.class.method_defined?(:update)
          body.update
        end
      end

      report_collisions(@bodies)
      out_of_bounds?
    end

    def out_of_bounds?
      @bodies.each do |body|
        if body.class.name.include?("HeadBlock")
          die if (body.center[:x] + (@BLOCK_SIZE / 2) > @SCREEN_WIDTH or
                  body.center[:x] - (@BLOCK_SIZE / 2) < 0 or
                  body.center[:y] + (@BLOCK_SIZE / 2) > @SCREEN_HEIGHT or
                  body.center[:y] - (@BLOCK_SIZE / 2) < 0)
        end
      end
    end

    def get_state
      state = {}
      state[:board] = {:size => {:width => @SCREEN_WIDTH, :height => @SCREEN_HEIGHT}}
      snakes = []

      @bodies.each do |body|
        snake_object = {}
        snake_object[:headblock] = body.get_object
        snakes << snake_object
      end

      state[:snakes] = snakes
      state[:score] = @score
      state[:game_over] = @game_over

      state
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
      {:center => @center,
       :color => "green",
       :size => {:x => 10,
                 :y => 10}}
    end
  end

  class HeadBlock
    attr_accessor :center, :size, :color, :client_id, :blocks

    def initialize(game, client_id)
      @client_id = client_id
      @game = game
      @color = "black"

      while !defined?(@center) do
        random_center = game.random_square
        @center = random_center if game.square_free?(random_center)
      end

      @direction = {:x => 1, :y => 0}
      @size = {:x => @game.BLOCK_SIZE, :y => @game.BLOCK_SIZE}
      @blocks = []
      @add_block = false
    end

    def set_color(color)
      @color = color
    end

    def update
      handle_keyboard(@game.last_moves[@client_id.to_s.to_sym])
      move
    end

    def collision(other_body)
      if other_body.class.name.include?("BodyBlock")
        @game.die
      elsif other_body.class.name.include?("FoodBlock")
        eat
      end
    end

    def eat
      @add_block = true
      @game.add_food
      @game.increase_score
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
      @center[:x] += @direction[:x] * @game.BLOCK_SIZE
      @center[:y] += @direction[:y] * @game.BLOCK_SIZE

      if @add_block == true
        block = BodyBlock.new(@game, prev_block_center)
        @game.add_body(block)
        @blocks << block
        @add_block = false
      end

      @blocks.each_with_index do |block, i|
        old_center = @blocks[i].center
        @blocks[i].center = {:x => prev_block_center[:x],
                             :y => prev_block_center[:y]}
        prev_block_center = old_center
      end
    end

    def get_object
      {:center => @center,
       :color => @color,
       :size => {:x => 10,
                 :y => 10}}
    end
  end

  class BodyBlock
    attr_accessor :center, :size

    def initialize(game, center)
      @game = game
      @center = center
      @size = @game.BLOCK_SIZE
    end

    def get_object
      {:center => @center,
       :color => "black",
       :size => {:x => @game.BLOCK_SIZE,
                 :y => @game.BLOCK_SIZE}}
    end
  end
end
