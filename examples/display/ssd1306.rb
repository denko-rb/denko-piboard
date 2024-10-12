#
# Use SSD1306 OLED, over I2C or SPI.
#
require 'denko/piboard'

board = Denko::PiBoard.new

# Use the first hardware I2C interface.
i2c_index = board.map[:i2cs].keys.first
bus       = Denko::I2C::Bus.new(board: board, index: i2c_index)
#
# Or a bit-bang I2C interface.
# bus = Denko::I2C::BitBang.new(board: board, pins: {scl: 228, sda: 270})

# Use the first hardware SPI interface, and its defined :cs0 pin.
# spi_index   = board.map[:spis].keys.first
# chip_select = board.map[:spis][spi_index][:cs0]
# bus         = Denko::SPI::Bus.new(board: board, index: spi_index)
#
# Or a bit-bang SPI interface.
# bus = Denko::SPI::BitBang.new(board: board, pins: {clock: 228, output: 270})

# I2C OLED, connected to I2C SDA and SCL.
oled = Denko::Display::SSD1306.new(bus: bus, rotate: true) # address: 0x3C is default

# SPI OLED, connected to SPI CLK and MOSI pins.
# select: and dc: pins must be given. reset is optional (can be pulled high instead).
# oled = Denko::Display::SSD1306.new(bus: bus, pins: {reset: 259, dc: 260, select: chip_select}, rotate: true)

# Draw some text on the OLED's canvas (a Ruby memory buffer).
canvas = oled.canvas
canvas.text_cursor = [27,60]
canvas.print("Hello World!")

# Add some shapes to the canvas.
baseline = 40
canvas.rectangle(10, baseline, 30, -30)
canvas.circle(66, baseline - 15, 15)
canvas.triangle(87, baseline, 117, baseline, 102, baseline - 30)

# Send the canvas to the OLED's graphics RAM so it shows.
oled.draw
board.finish_write
