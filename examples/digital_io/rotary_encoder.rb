#
# WARNING: This performs significantly better when used with a PiBoard instance
# (Linux SBC), compared to a Board instance (attached microcontroller),
# but still might not be perfect.
#
require 'denko/piboard'

PIN_A     = 260
PIN_B     = 76

board = Denko::PiBoard.new
encoder = Denko::DigitalIO::RotaryEncoder.new board: board,
                                              pins: { a: PIN_A, b: PIN_B },
                                              divider: 1,                 # Default. Applies only to Board. Read pin every 1ms.
                                              debounce_time: 1,           # Default. Applies only to PiBoard. Debounce filter set to 1 microsecond.
                                              counts_per_revolution: 60   # Default

# Reverse direction if needed.
# encoder.reverse

# Reset angle and count to 0.
encoder.reset

encoder.add_callback do |state|
  change_printable = state[:change].to_s
  change_printable = "+#{change_printable}" if state[:change] > 0

  puts "Encoder Change: #{change_printable} | Count: #{state[:count]} | Angle: #{state[:angle]}\xC2\xB0"
end

sleep
