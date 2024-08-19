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

PIN = 226
board = Denko::PiBoard.new(pwm_chips: OPI_ZERO2W_PWMS)
buzzer = Denko::PulseIO::Buzzer.new(board: board, pin: PIN)

C4 = 262
D4 = 294
E4 = 330

notes = [
        [E4, 1], [D4, 1], [C4, 1], [D4, 1], [E4, 1], [E4, 1], [E4, 2],
        [D4, 1], [D4, 1], [D4, 2],          [E4, 1], [E4, 1], [E4, 2],
        [E4, 1], [D4, 1], [C4, 1], [D4, 1], [E4, 1], [E4, 1], [E4, 1], [E4, 1],
        [D4, 1], [D4, 1], [E4, 1], [D4, 1], [C4, 4],
        ]

bpm = 240
beat_time = 60.to_f / bpm

notes.each do |note|
  buzzer.tone(note[0], (note[1] * beat_time))
end

# Only works for PiBoard.
sleep 0.100 while (board.tone_busy(PIN) == 1)

buzzer.stop
board.finish_write
