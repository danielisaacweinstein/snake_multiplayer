class HeadBlock
	attr_accessor :center, :size, :color

	def initialize(center, size)
		@center = center
		@size = {:x => 10, :y => 10} # BLOCK_SIZE (need to centralize)
		@direction = {:x => 1, :y => 0}
		@blocks = []
		@last_move = 0
		@add_block = false
	end

	def get_object
		{:center => @center, :color => "red", :size => {:x => 10, :y => 10}}
	end
end

class WallBlock
	attr_accessor :center, :size, :color

	def initialize(center, size)
		@center = center
		@size = size
		@color = "black"
	end
end

class BodyBlock
	attr_accessor :center, :size, :color

	def initialize(center)
		@center = center
		@size = {:x => BLOCK_SIZE, :y => BLOCK_SIZE}
		@color = "black"
	end
end

class MultisnakeGame
	def initialize
		@BLOCK_SIZE = 10
		@size = {:x => 500, :y => 500}
		@center = {:x => @size[:x] / 2, :y => @size[:y] / 2}

		# @bodies = create_walls << HeadBlock.new(@center, @size)
		@bodies = []
		@bodies << HeadBlock.new(@center, @size)
	end

	def create_walls
		walls = []
		walls << (WallBlock.new({:x => @center[:x], :y => @BLOCK_SIZE / 2},
														{:x => @size[:x], :y => @BLOCK_SIZE})); 									# Top

		walls << (WallBlock.new({:x => @size[:x] - @BLOCK_SIZE / 2, :y => @center[:y]},
														{:x => @BLOCK_SIZE, :y => @size[:y] - @BLOCK_SIZE * 2})); # Right

		walls << (WallBlock.new({:x => @center[:x], :y => @size[:y] - @BLOCK_SIZE / 2},
														{:x => @size[:x], :y => @BLOCK_SIZE}));									# Bottom

		walls << (WallBlock.new({:x => @BLOCK_SIZE / 2, :y => @center[:y]},
														{:x => @BLOCK_SIZE, :y => @size[:y] - @BLOCK_SIZE * 2})); # Left
		walls
	end

	def get_state
		state = []
		@bodies.each do |body|
			state << body.get_object.to_s
		end
		state
	end
end