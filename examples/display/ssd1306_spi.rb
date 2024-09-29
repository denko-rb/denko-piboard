#
# Example using an SSD1306 driven OLED screen over SPI on Radxa Zero 3W.
#
require 'denko/piboard'

board = Denko::PiBoard.new

# The SSD1306 OLED connects to either an I2C or SPI bus, depending on the model you have.
# Bus setup exampels in order:
#   I2C Hardware
#   I2C Bit-Bang
#   SPI Hardware
#   SPI Bit-Bang
#
# bus = Denko::I2C::Bus.new(board: board)
# bus = Denko::I2C::BitBang.new(board: board, pins: {scl: 36, sda: 100})
# bus = Denko::SPI::Bus.new(board: board)
bus = Denko::SPI::BitBang.new(board: board, pins: {clock: 36, output: 100})

# I2C OLED, connected to I2C SDA and SCL.
# oled = Denko::Display::SSD1306.new(bus: bus, rotate: true) # address: 0x3C is default

# SPI OLED, connected to SPI CLK and MOSI pins.
# select: and dc: pins must be given. reset is optional (can be pulled high instead).
oled = Denko::Display::SSD1306.new(bus: bus, pins: {reset: 101, dc: 102, select: 103}, rotate: true)

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
