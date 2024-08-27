require 'denko/piboard'

GPIO_CHIP = 0
SCL_PIN   = 228
SDA_PIN   = 270

# Create a board map for your SBC.
board_map = File.join(File.dirname(__FILE__), "../board_maps/orange_pi_zero_2w.yml")
board = Denko::PiBoard.new(board_map)

bus = Denko::I2C::BitBang.new(board: board, pins: {scl: SCL_PIN, sda: SDA_PIN})
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
