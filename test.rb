require 'eventmachine'

EventMachine.run do
  timer = EventMachine::PeriodicTimer.new(1) do
    puts "Timer fired at #{Time.now}"
  end
  # timer.interval = 1
  # timer.interval = 20
end


