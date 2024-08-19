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
ir = Denko::PulseIO::IRTransmitter.new(board: board, pin: 226)

# NEC Raw-Data=0xF708FB04. LSBFIRST, so the binary for each hex digit below is backward.
code =  [ 9000, 4500,                                 # Start bit
          560, 560, 560, 560, 560, 1690, 560, 560,    # 0010 0x4 command
          560, 560, 560, 560, 560, 560, 560, 560,     # 0000 0x0 command
          560, 1690, 560, 1690, 560,560, 560, 1690,   # 1101 0xB command inverted
          560, 1690, 560, 1690, 560, 1690, 560, 1690, # 1111 0xF command inverted
          560, 560, 560, 560, 560, 560, 560, 1690,    # 0001 0x8 address
          560, 560, 560, 560, 560, 560, 560, 560,     # 0000 0x0 address
          560, 1690, 560, 1690, 560, 1690, 560, 560,  # 1110 0x7 address inverted
          560, 1690, 560, 1690, 560, 1690, 560, 1690, # 1111 0xF address inverted
          560]                                        # Stop bit

ir.emit(code)
board.finish_write
