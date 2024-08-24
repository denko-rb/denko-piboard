#
# Example using AHT10 sensor over I2C, for temperature and humidity.
#
require 'denko/piboard'

# Create a board map for your SBC, so Denko can map I2C pins to GPIOs.
board_map = File.join(File.dirname(__FILE__), "../board_maps/orange_pi_zero_2w.yml")
board = Denko::PiBoard.new(board_map)

# We also need to tell the I2C bus what its SDA pin is.
sda_pin = board.i2cs.values.first[:sda]
bus = Denko::I2C::Bus.new(board: board, pin: sda_pin)

sensor = Denko::Sensor::AHT10.new(bus: bus) # address: 0x38 default

# Get the shared #print_tph_reading method to print readings neatly.
require_relative 'neat_tph_readings'

# Poll it and print readings.
sensor.poll(5) do |reading|
  print_tph_reading(reading)
end

sleep