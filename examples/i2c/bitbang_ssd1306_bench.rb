require 'denko/piboard'

START_ARRAY = [0, 33, 0, 127, 34, 0, 7]
PATTERN_1   = [64] + Array.new(1024) { 0b00110011 }
PATTERN_2   = [64] + Array.new(1024) { 0b11001100 }

SCL   = 228
SDA   = 270
board = Denko::PiBoard.new()
bus   = Denko::I2C::BitBang.new(board: board, pins: {scl: SCL, sda: SDA})
oled  = Denko::Display::SSD1306.new(bus: bus, rotate: true)


FRAME_COUNT = 400
start = Time.now
(FRAME_COUNT / 2).times do
  oled.i2c_write(START_ARRAY)
  oled.i2c_write(PATTERN_1)
  oled.i2c_write(START_ARRAY)
  oled.i2c_write(PATTERN_2)
end
board.finish_write
finish = Time.now

fps = FRAME_COUNT / (finish - start)
# Also calculate C calls per second, using roughly 23 calls per byte written.
cps = (START_ARRAY.length + ((PATTERN_1.length + PATTERN_2.length) / 2) + 2) * 23 * fps
cps = (cps / 1000.0).round

puts "SSD1306 benchmark result: #{fps.round(2)} fps | #{cps}k C calls/s"
