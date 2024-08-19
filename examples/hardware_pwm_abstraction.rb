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
led = Denko::LED.new(board: board, pin: 226)

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
