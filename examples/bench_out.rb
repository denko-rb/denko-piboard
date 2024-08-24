require 'denko/piboard'

PIN       = 272
COUNT     = 1000000

board = Denko::PiBoard.new
output = Denko::DigitalIO::Output.new(board: board, pin: PIN)

t1 = Time.now
COUNT.times do
  output.high
  output.low
end
t2 = Time.now
board.finish_write

puts "Toggles per second: #{COUNT.to_f / (t2 - t1).to_f}"
