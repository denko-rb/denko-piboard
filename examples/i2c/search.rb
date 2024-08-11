require 'denko'
require 'denko/piboard'

board = Denko::PiBoard.new i2c_devices: [{index: 3, sda: 264}]
bus = Denko::I2C::Bus.new(board: board, pin: 264)

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
