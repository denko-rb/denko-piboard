require 'denko/piboard'

PIN = 227

# Create a board map for your SBC, so Denko can map hardware PWM channels to GPIOs.
board_map = File.join(File.dirname(__FILE__), "board_maps/orange_pi_zero_2w.yml")

board = Denko::PiBoard.new(board_map)
servo = Denko::Motor::Servo.new(board: board, pin: PIN)

[0, 90, 180, 90].cycle do |angle|
  servo.position = angle
  sleep 0.5
end
