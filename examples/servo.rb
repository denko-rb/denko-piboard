require 'denko/piboard'

#
# GPIO to PWM channel mappings for the Orange Pi Zero 2W
# Note: Channels 3 and 4 are only usable if UART0 is disabled in device tree.
#
OPI_ZERO2W_PWMS = [
  { index: 0,
    gpios: {
      227 => 1,
      226 => 2,
      224 => 3,
      225 => 4,
    }
  }
]

board = Denko::PiBoard.new(pwm_chips: OPI_ZERO2W_PWMS)
servo = Denko::Motor::Servo.new(pin: 227, board: board)

[0, 90, 180, 90].cycle do |angle|
  servo.position = angle
  sleep 0.5
end
