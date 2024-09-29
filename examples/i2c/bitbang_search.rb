#
# Search for connected devices on a bit-bang I2C bus.
#
require 'denko/piboard'

SCL   = 228
SDA   = 270
board = Denko::PiBoard.new
bus   = Denko::I2C::BitBang.new(board: board, pins: {scl: SCL, sda: SDA})

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
