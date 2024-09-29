#
# Example using an SSD1306 driven OLED screen over SPI on Radxa Zero 3W.
#
require 'denko/piboard'

board = Denko::PiBoard.new

# The SSD1306 OLED connects to either an I2C or SPI bus, depending on the model you have.
# Bus setup examples in order:
#   I2C Hardware (For index: give N from: /dev/i2c-N being used)
#   I2C Bit-Bang
#   SPI Hardware (For index: give N from: /dev/spidevN.0 being used)
#   SPI Bit-Bang
#
bus = Denko::I2C::Bus.new(board: board, index: 3)
# bus = Denko::I2C::BitBang.new(board: board, pins: {scl: 228, sda: 270})
# bus = Denko::SPI::Bus.new(board: board, index: 1)
# bus = Denko::SPI::BitBang.new(board: board, pins: {clock: 228, output: 270})

# I2C OLED, connected to I2C SDA and SCL.
oled = Denko::Display::SSD1306.new(bus: bus, rotate: true) # address: 0x3C is default

# SPI OLED, connected to SPI CLK and MOSI pins.
# select: and dc: pins must be given. reset is optional (can be pulled high instead).
# oled = Denko::Display::SSD1306.new(bus: bus, pins: {reset: 259, dc: 260, select: 76}, rotate: true)

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
