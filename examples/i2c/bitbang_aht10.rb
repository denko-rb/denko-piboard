#
# Example using AHT10 sensor over I2C, for temperature and humidity.
#
require 'denko/piboard'

SCL   = 228
SDA   = 270
board = Denko::PiBoard.new()
bus   = Denko::I2C::BitBang.new(board: board, pins: {scl: SCL, sda: SDA})
aht10 = Denko::Sensor::AHT10.new(bus: bus) # address: 0x38 default

# Get the shared #print_tph_reading method to print readings neatly.
require_relative '../sensor/neat_tph_readings'

# Poll it and print readings.
aht10.poll(5) do |reading|
  print_tph_reading(reading)
end

sleep
