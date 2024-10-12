#
# Use a DHT class (DHT-11 / DHT-22) sensor for temperature and humidity.
#
require 'denko/piboard'
require_relative 'neat_tph_readings'

DHT_PIN = 267

board = Denko::PiBoard.new
sensor = Denko::Sensor::DHT.new(board: board, pin: DHT_PIN)

sensor.read
puts "Temperature unit helpers: #{sensor.temperature} \xC2\xB0C | #{sensor.temperature_f} \xC2\xB0F | #{sensor.temperature_k} K"
puts

# Don't try to read it again too quickly.
sleep(1)

# Poll it and print readings.
sensor.poll(5) do |reading|
  print_tph_reading(reading)
end

sleep
