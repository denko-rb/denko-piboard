#
# Use an HC-SR04 ultrasonic distance sensor.
#
require 'denko/piboard'

ECHO_PIN    = 228
TRIGGER_PIN = 270

board = Denko::PiBoard.new
hcsr04 = Denko::Sensor::HCSR04.new(board: board, pins: {trigger: TRIGGER_PIN, echo: ECHO_PIN})

hcsr04.poll(1) do |distance|
  puts "Distance: #{distance} mm"
end

sleep
