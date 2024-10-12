#
# AHT10 sensor over I2C, for temperature and humidity.
#
require 'denko/piboard'
require_relative 'neat_tph_readings'

board = Denko::PiBoard.new
# Use the first hardware I2C interface.
i2c_index = board.map[:i2cs].keys.first
bus       = Denko::I2C::Bus.new(board: board, index: i2c_index)

# Poll it and print readings.
sensor.poll(5) do |reading|
  print_tph_reading(reading)
end

sleep
