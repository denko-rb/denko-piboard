#
# Example of LED connected through an output shift register (74HC595).
# Can be used over either a bit bang or hardware SPI interface.
#
require 'denko/piboard'

LED_PIN = 3 # On the register's parallel outputs

# Use board map ~/.denko_piboard_map.yml
board     = Denko::PiBoard.new

# Use the first hardware SPI interface, and it's defined :cs0 pin.
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

# Turn the LED on by shifting 1 to the correct bit and writing it.
register.spi_write([0b1 << LED_PIN])

# OutputRegister is a BoardProxy. DigitalOutputs can treat it as a Board.
led = Denko::LED.new(board: register, pin: 0)

# Blink the LED and sleep the main thread.
led.blink 0.5
sleep
