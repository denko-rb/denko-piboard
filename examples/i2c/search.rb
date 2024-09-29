#
# Search for connected devices on a hardware I2C bus.
#
require 'denko/piboard'

board = Denko::PiBoard.new
# index: corresponds to Linux I2C device number. /dev/i2c-3 in this case.
bus = Denko::I2C::Bus.new(board: board, index: 3)

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
