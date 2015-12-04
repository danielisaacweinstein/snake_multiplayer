BLOCK_SIZE = 10

class MultisnakeGame
	attr_accessor :center, :size

	def initialize()
		@SCREEN_HEIGHT = 500
		@SCREEN_WIDTH = 500
		@size = {:x => @SCREEN_HEIGHT, :y => @SCREEN_WIDTH}
		@center = {:x => @size[:x] / 2, :y => @size[:y] / 2}

		@bodies = []
		@bodies << HeadBlock.new(self)

	end

	# In the JavaScript version, we ultimately got keyboard state
	# from the Keyboarder object that was created on the headblock.
	# For now, we need to get the updates from the client, and we
	# get information from the client via the websocket connection
	# which speaks to the server. Passing it through tick. Not sure
	# if this is an unwise design choice.
	def tick(key_code)
		update(key_code)
		get_state
	end

	def update(key_code)
		@bodies.each do |body|
			body.update(key_code) if body.class.method_defined?(:update)
		end
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

end

class HeadBlock
	attr_accessor :center, :size, :color

	def initialize(game)
		@center = {:x => game.center[:x], :y => game.center[:y]}
		@direction = {:x => 1, :y => 0}
		@size = {:x => BLOCK_SIZE, :y => BLOCK_SIZE}
		@blocks = []

		@last_move = Time.now
		@add_block = false
	end

	def update(key_code)
		handle_keyboard(key_code)

		now = Time.now
		if (now > @last_move)
			move
			@last_move = now
		end
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
		@center[:x] += @direction[:x] * BLOCK_SIZE
		@center[:y] += @direction[:y] * BLOCK_SIZE
	end

	def get_object
		{:center => @center, :color => "red", :size => {:x => 10, :y => 10}}
	end

end