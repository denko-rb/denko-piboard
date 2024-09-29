require 'denko/piboard'

PIN       = 272
COUNT     = 1000000

board = Denko::PiBoard.new
output = Denko::DigitalIO::Output.new(board: board, pin: PIN)

t1 = Time.now
COUNT.times do
  # If bit-banging in Ruby, this is the level to work at.
  board.digital_write(PIN, 1)
  board.digital_write(PIN, 0)

  # These methods set output.state on every call (slower).
  # output.high
  # output.low
end
t2 = Time.now
board.finish_write

puts "Toggles per second: #{COUNT.to_f / (t2 - t1).to_f}"
