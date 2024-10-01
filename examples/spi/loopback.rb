require 'denko'
require 'denko/piboard'

# Use board map from ~/.denko_piboard_map.yml
board = Denko::PiBoard.new

# Use the first hardware SPI interface, and its defined :cs0 pin.
spi_index   = board.map[:spis].keys.first
chip_select = board.map[:spis][spi_index][:cs0]
bus         = Denko::SPI::Bus.new(board: board, index: spi_index)

TEST_DATA = [0, 1, 2, 3, 4, 5, 6, 7]

# Create a simple test component class.
class SPITester
  include Denko::SPI::Peripheral::SinglePin
end
spi_tester = SPITester.new(bus: bus, pin: chip_select)
spi_tester.add_callback do |rx_bytes|
  # If MOSI and MISO are connected this should match TEST_DATA.
  # If not, should be 8 bytes of 255.
  puts "Result      : #{rx_bytes.inspect}"
end

# Send and receive same data.
puts "Tx 8 / Rx 8 : #{TEST_DATA.inspect}"
spi_tester.spi_transfer(write: TEST_DATA, read: 8)

puts "Tx 8 / Rx 12: #{TEST_DATA.inspect}"
spi_tester.spi_transfer(write: TEST_DATA, read: 12)

puts "Tx 8 / Rx 4 : #{TEST_DATA.inspect}"
spi_tester.spi_transfer(write: TEST_DATA, read: 4)

# Wait for read callback to run.
sleep 1
board.finish_write
