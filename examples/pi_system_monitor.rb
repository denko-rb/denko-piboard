#
# This example uses an SSD1306 OLED display, connected to the Pi's I2C1 interface.
# I2C1 pins are GPIO2 (SDA) and GPIO3 (SCL).
# 
# CPU usage is measured using `mpstat`. To install it:
#     sudo apt install sysstat
#
# RAM usage is measured using `free`.
#
# Each loop, the OLED refreshes, showing date, time, CPU usage and RAM usage.
#
require 'dino/piboard'

# Special character that fills a 4x6 rectangle.
# Used to make bar graphs for CPU and RAM usage.
BAR_ELEMENT = [0x00, 0x7E, 0x7E, 0x7E, 0x00]

board = Dino::PiBoard.new
i2c = Dino::I2C::Bus.new(board: board, pin: :SDA)

oled = Dino::Display::SSD1306.new(bus: i2c, rotate: true)
canvas = oled.canvas

# Only do this once since total RAM won't change.
total_ram = `free -h | awk 'NR==2 {gsub("Mi", "", $2); print $2}'`
total_ram = total_ram.to_i
ram_bar_factor = total_ram / 25.0

loop do
  # CPU Usage (automatically delays for 1 second)
  mpstat_result = `mpstat -P ALL 1 1 | awk '/^Average:/ && ++count == 2 {print 100 - $12"%"}'`
  cpu_percent = mpstat_result.chop.to_f
  
  canvas.clear
  canvas.text_cursor = [0, 16]
  canvas.print "CPU Usage:  #{('%.3f' % cpu_percent).rjust(8, ' ')}%"
  
  canvas.text_cursor = [0, 24]
  (cpu_percent / 4).ceil.times { canvas.raw_char(BAR_ELEMENT) }
  
  # RAM Usage
  ram_usage = `free -h | awk 'NR==2 {gsub("Mi", "", $3); print $3}'`
  ram_usage = ram_usage.to_i

  canvas.text_cursor = [0, 40]
  ram_string = "#{ram_usage}/#{total_ram}MB"
  canvas.print "RAM Usage:#{ram_string.rjust(11, ' ')}"
  
  canvas.text_cursor = [0, 48]
  (ram_usage / ram_bar_factor).ceil.times { canvas.raw_char(BAR_ELEMENT) }
  
  # Date and time just before write.
  canvas.text_cursor = [0,0]
  canvas.print(Time.now.strftime('%a %b %d %-l:%M %p'))
  
  # Only refresh the area in use.
  oled.draw(0, 127, 0, 56)
end
