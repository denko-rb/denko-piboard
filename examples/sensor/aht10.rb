#
# Example using AHT10 sensor over I2C, for temperature and humidity.
#
require 'denko/piboard'
require_relative 'neat_tph_readings'

board = Denko::PiBoard.new
# index: corresponds to Linux I2C device number. /dev/i2c-3 in this case.
bus = Denko::I2C::Bus.new(board: board, index: 3)

# Poll it and print readings.
sensor.poll(5) do |reading|
  print_tph_reading(reading)
end

sleep
