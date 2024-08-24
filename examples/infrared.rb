require 'denko/piboard'

PIN = 226

# Create a board map for your SBC, so Denko can map hardware PWM channels to GPIOs.
board_map = File.join(File.dirname(__FILE__), "board_maps/orange_pi_zero_2w.yml")

board = Denko::PiBoard.new(board_map)
ir = Denko::PulseIO::IRTransmitter.new(board: board, pin: PIN)

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
