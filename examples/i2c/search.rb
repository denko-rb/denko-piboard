require 'denko'
require 'denko/piboard'

# Create a board map for your SBC, so Denko can map I2C pins to GPIOs.
board_map = File.join(File.dirname(__FILE__), "../board_maps/orange_pi_zero_2w.yml")
board = Denko::PiBoard.new(board_map)

# We also need to tell the I2C bus what its SDA pin is.
sda_pin = board.i2cs.values.first[:sda]
bus = Denko::I2C::Bus.new(board: board, pin: sda_pin)

bus.search

if bus.found_devices.empty?
  puts "No devices found on I2C bus"
else
  puts "I2C device addresses found:"
  bus.found_devices.each do |address|
    # Print as hexadecimal.
    puts "0x#{address.to_s(16).upcase}"
  end
end

puts
board.finish_write
