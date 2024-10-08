#
# This helper method can be used in temp/pressure/humidity sensor examples.
# Give a hash with readings as float values and it prints them neatly.
#
def print_tph_reading(reading)
  elements = []

  # Temperature
  if reading[:temperature]
    formatted_temp = reading[:temperature].to_f.round(2).to_s.ljust(5, '0')
    elements << "Temperature: #{formatted_temp} \xC2\xB0C"
  end

  # Pressure
  if reading[:pressure]
    formatted_pressure = reading[:pressure].round(2).to_s.ljust(7, '0')
    elements << "Pressure: #{formatted_pressure} Pa"
  end

  # Humidity
  if reading[:humidity]
    formatted_humidity = reading[:humidity].round(2).to_s.ljust(5, '0')
    elements << "Humidity: #{formatted_humidity} %"
  end

  return if elements.empty?

  # Time
  print "#{Time.now.strftime '%Y-%m-%d %H:%M:%S'} - "

  puts elements.join(" | ")
end
