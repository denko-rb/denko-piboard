require 'denko/piboard'

# Either a regular GPIO (uses software PWM) or a GPIO with a hardware PWM channel.
PIN = 226

board = Denko::PiBoard.new
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
  led.duty = v
  sleep 0.020
end
