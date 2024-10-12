#
# Use a servo motor on a hardware PWM pin. Should raise an error
# if the GPIO given does not have a hardware PWM channel multiplexed.
#
require 'denko/piboard'

# Must be assigned to a hardware PWM channel in your board map.
PIN = 226

board = Denko::PiBoard.new
servo = Denko::Motor::Servo.new(board: board, pin: PIN)

[0, 90, 180, 90].cycle do |angle|
  servo.position = angle
  sleep 0.5
end
