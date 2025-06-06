#
# Use a Dallas DS18B20 temperature sensor on a 1-Wire bus.
#
require 'denko/piboard'

PIN = 256

board = Denko::PiBoard.new
bus = Denko::OneWire::Bus.new(board: board, pin: PIN)

# The bus detects parasite power automatically when initialized.
# It can tell that parasite power is in use, but not by WHICH devices.
if bus.parasite_power
  puts "Parasite power detected..."; puts
end

# Call #device_present to reset the bus and return presence pulse as a boolean.
if bus.device_present?
  puts "Devices present on bus..."; puts
else
  puts "No devices present on bus... Quitting..."
  return
end

# Calling #search finds connected devices and stores them in #found_devices.
# Each hash contains a device's ROM address and matching Ruby class if one exists.
bus.search
count = bus.found_devices.count
puts "Found #{count} device#{'s' if count > 1} on the bus:"
puts bus.found_devices.inspect; puts

# We can use the search results to setup instances of the device classes.
ds18b20s = []
bus.found_devices.each do |d|
  if d[:class] == Denko::Sensor::DS18B20
    ds18b20s << d[:class].new(bus: bus, address: d[:address])
  end
end

#  Format a reading for printing on a line.
def print_reading(reading, sensor)
  print "#{Time.now.strftime '%Y-%m-%d %H:%M:%S'} - "
  print "Serial(HEX): #{sensor.serial_number} | Res: #{sensor.resolution} bits | "

  if reading[:crc_error]
    puts "CRC check failed for this reading!"
  else
    fahrenheit = (reading[:temperature] * 1.8 + 32).round(1)
    puts "#{reading[:temperature]} \xC2\xB0C | #{fahrenheit} \xC2\xB0F"
  end
end

ds18b20s.each do |sensor|
  sensor.poll(5) do |reading|
    print_reading(reading, sensor)
  end
end

sleep
