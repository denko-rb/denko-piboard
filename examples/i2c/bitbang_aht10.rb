#
# Example using AHT10 sensor over I2C, for temperature and humidity.
#
require 'denko/piboard'

GPIO_CHIP = 0
SCL_PIN   = 228
SDA_PIN   = 270

# Create a board map for your SBC.
board_map = File.join(File.dirname(__FILE__), "../board_maps/orange_pi_zero_2w.yml")
board = Denko::PiBoard.new(board_map)

bus = Denko::I2C::BitBang.new(board: board, pins: {scl: SCL_PIN, sda: SDA_PIN})

sensor = Denko::Sensor::AHT10.new(bus: bus) # address: 0x38 default

# Get the shared #print_tph_reading method to print readings neatly.
require_relative '../sensor/neat_tph_readings'

# Poll it and print readings.
sensor.poll(5) do |reading|
  print_tph_reading(reading)
end

sleep
