require 'yaml'

# `whoami` returns the name of the user running this script.
#
# If you automate this to run on startup (as root), you must put
# your literal Linux username here instead. If not, it will attempt
# to load a map from root's home, and root will get permissions, not you.
#
USERNAME = `whoami`.strip

GPIO_GROUP_NAME = "gpio"
I2C_GROUP_NAME = "i2c"
SPI_GROUP_NAME = "spi"
PWM_GROUP_NAME = "pwm"

MAP_FILENAME = ".denko_piboard_map.yml"
$added_to_group = false

# Create groups and add the user to them as needed.
def group_setup(group_name)
  group_line = `egrep -i "^#{group_name}" /etc/group`

  if group_line.empty?
    `sudo groupadd #{group_name}`
  end

  unless group_line.match(/#{USERNAME}/)
    `sudo usermod -aG #{group_name} #{USERNAME}`
    print "Added user #{USERNAME} to group #{group_name}. "
    $added_to_group = true
  else
    print "User #{USERNAME} already in group #{group_name}. "
  end
end

# Change gpiochip ownership and permissions.
def setup_gpio
  gpiochips = $map["pins"].each_value.map { |pin_def| pin_def["chip"] }.uniq
  group_setup(GPIO_GROUP_NAME) unless gpiochips.empty?
  gpiochips.each do |chip_index|
    `sudo chgrp #{GPIO_GROUP_NAME} /dev/gpiochip#{chip_index}*`
    `sudo chmod g+rw /dev/gpiochip#{chip_index}*`
    puts "Set permissions for /dev/gpiochip#{chip_index}"
  end
end

# Change I2C ownership and permissions
def setup_i2c
  i2cs = $map["i2cs"].keys
  group_setup(I2C_GROUP_NAME) unless i2cs.empty?
  i2cs.each do |i2c_index|
    dev = "/dev/i2c-#{i2c_index}"
    `sudo chgrp #{I2C_GROUP_NAME} #{dev}`
    `sudo chmod g+rw #{dev}`
    puts "Set permissions for #{dev}"
  end
end

# Change SPI ownership and permissions
def setup_spi
  spis = $map["spis"].keys
  group_setup(SPI_GROUP_NAME) unless spis.empty?
  spis.each do |spi_index|
    dev = "/dev/spidev#{spi_index}"
    `sudo chgrp #{SPI_GROUP_NAME} #{dev}*`
    `sudo chmod g+rw #{dev}*`
    puts "Set permissions for #{dev}.*"
  end
end

def setup_pwm
# Change PWM ownership and permissions
  pwms = $map["pwms"]
  unless pwms.empty?
    group_setup(PWM_GROUP_NAME)
    print "Exported and set permissions for: /sys/class/pwm/{"
  end

  i = 0
  pwms.each_value do |hash|
    i += 1
    chip = hash["pwmchip"]
    chan = hash["channel"]
    chip_dir = "/sys/class/pwm/pwmchip#{chip}"
    channel_dir = "/sys/class/pwm/pwmchip#{chip}/pwm#{chan}"

    `sudo chgrp -RH #{PWM_GROUP_NAME} #{chip_dir}`
    `sudo echo #{chan} > #{chip_dir}/export` unless Dir.exist?(channel_dir)
    `sudo chmod -R g+rw #{channel_dir}`

    print channel_dir.gsub("/sys/class/pwm/", "")
    print ", " unless i == pwms.length
  end
  puts "}"
end

# Load map
home = Dir.home(USERNAME)
yaml_path = home +"/#{MAP_FILENAME}"
$map = YAML.load_file(yaml_path)
puts

case ARGV[0]
when "gpio"
  setup_gpio
when "i2c"
  setup_i2c
when "spi"
  setup_spi
when "pwm"
  setup_pwm
else
  setup_gpio
  setup_i2c
  setup_spi
  setup_pwm
end

# Notify user
if $added_to_group
  puts
  puts "User #{USERNAME} has been added to new group(s). Log out, then log back in for this to take effect."
end
puts
