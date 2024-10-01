#
# Example of LED connected through an output shift register (74HC595).
# Can be used over either a bit bang or hardware SPI interface.
#
require 'denko/piboard'

LED_PIN = 3 # On the register's parallel outputs

# Use board map from ~/.denko_piboard_map.yml
board = Denko::PiBoard.new

# Use the first hardware SPI interface, and its defined :cs0 pin.
spi_index   = board.map[:spis].keys.first
chip_select = board.map[:spis][spi_index][:cs0]
bus         = Denko::SPI::Bus.new(board: board, index: spi_index)

# OutputRegister needs a bus and pin (chip select).
# Other options and their defaults:
#     bytes:          1          - For daisy-chaining registers
#     spi_frequency:  1000000    - Only affects hardware SPI interfaces
#     spi_mode:       0
#     spi_bit_order:  :msbfirst
#
register = Denko::SPI::OutputRegister.new(bus: bus, pin: chip_select)

# Turn on the LED by setting the corresponding bit, then writing to the register.
register.bit_set(LED_PIN, 1)
register.write

# OutputRegister is a BoardProxy. It has #digital_write, and other methods from Board.
register.digital_write(LED_PIN, 0)

# DigitalOutputs can treat it as a Board.
led = Denko::LED.new(board: register, pin: LED_PIN)

# Blink the LED and sleep the main thread.
led.blink 0.5
sleep
