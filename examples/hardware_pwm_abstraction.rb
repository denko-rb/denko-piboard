require 'denko/piboard'

PIN = 226

# Create a board map for your SBC, so Denko can map hardware PWM channels to GPIOs.
board_map = File.join(File.dirname(__FILE__), "board_maps/orange_pi_zero_2w.yml")

board = Denko::PiBoard.new(board_map)
led = Denko::LED.new(board: board, pin: PIN)

5.times do
  led.on
  sleep 0.2
  led.off
  sleep 0.2
end

# Seamless loop from 0-100 and back.
values = (0..100).to_a + (1..99).to_a.reverse

values.cycle do |v|
  led.write(v)
  sleep 0.020
end
