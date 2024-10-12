# denko-piboard

Use Linux single-board-computer GPIO in Ruby.

```ruby
# Turn LED on when a button is held down, off when released.
require 'denko/piboard'

board  = Denko::PiBoard.new
led    = Denko::LED.new(board: board, pin: 260)
button = Denko::DigitalIO::Button.new(board: board, pin: 259, mode: :input_pullup)

# Callback fires when button is down (0)
button.down do
  puts "Button down"
  led.on
end

# Callback fires when button is up (1)
button.up do
  puts "Button up"
  led.off
end

# Sleep main thread. Ctrl+C to quit.
sleep
```

## Linux GPIO Features
- [x] Internal Pull-Up/Down
- [x] Open Drain/Source
- [x] Digital Read/Write
- [x] Digital Listen (Alerts)
  - Interrupt driven, unlike `denko` microcontroller implementation 1ms polling
  - Built in software debounce (1us by default)
  - Alerts are read from a FIFO queue up to 65,536. Oldest alerts are lost first.
- [ ] Analog Read (ADC)
- [ ] Analog Write (DAC)
- [x] Software PWM Out (any pin)
- [x] Hardware PWM Out (specific pins per board)
- [x] Tone Out (via Software PWM or Hardware PWM)
- [x] Servo (via Hardware PWM)
- [x] Infrared Out (via Hardware PWM)
- [x] Hardware I2C
  - [x] Multiple interfaces
- [x] Hardware SPI
  - [x] Multiple interfaces
  - [x] WS2812 addressable LED via SPI MOSI
  - [ ] SPI Listeners from `denko`
- [ ] UART
- [x] Ultrasonic Input (for HC-SR04 and similar)
- [x] Pulse Sequence Input (for DHT enviro sensors and similar)
- [x] Bit-Bang I2C
- [x] Bit-Bang SPI
- [x] Bit-Bang 1-Wire

### Incompatible Features
- EEPROM
  - Use filesystem for persistence instead

## Support

#### Hardware

:green_heart: Known working
:heart: Awaiting testing
:question: Might work. No hardware

|    Chip           | Status          | Products                               | Notes |
| :--------         | :------:        | :----------------------                |------ |
| Allwinner H618    | :green_heart:   | Orange Pi Zero 2W                      | DietPi
| Rockchip RK3566   | :green_heart:   | Radxa Zero 3W/E, Radxa Rock 3C         | Armbian
| BCM2835           | :green_heart:   | Raspberry Pi 1, Raspberry Pi Zero (W)  | Raspberry Pi OS
| BCM2836/7         | :question:      | Raspberry Pi 2                         |
| BCM2837A0/B0      | :green_heart:   | Raspberry Pi 3                         | Raspberry Pi OS
| BCM2711           | :green_heart:   | Raspberry Pi 4, Raspberry Pi 400       | Raspberry Pi OS
| BCM2710A1         | :green_heart:   | Raspberry Pi Zero 2W                   | Raspberry Pi OS
| BCM2712           | :question:      | Raspberry Pi 5                         |

#### Software

- Operating Systems:
  - DietPi (Bookworm)
  - Amrbian (Bookworm)
  - Raspberry Pi OS (Bookworm)

- Rubies:
  - Ruby 3.3.5 +YJIT

## Install

#### Install the lg C library
```console
# Requirements to install lgpio C
sudo apt install swig python3-dev python3-setuptools gcc make

# Temporary fork of: wget https://github.com/joan2937/lg
wget https://github.com/vickash/lg/archive/refs/heads/master.zip

# Install lgpio C
unzip master.zip
cd lg-master
make
sudo make install
```

#### Install the denko-piboard gem
```console
# Latest Ruby + YJIT from rbenv works best, but Ruby 3 from apt works too.
# Install system Ruby anyway if automating permissions startup script.
sudo apt install ruby ruby-dev

sudo gem install denko-piboard
```
**Note:** `sudo` may be needed before `gem install` if using the system Ruby.

## Enable Hardware

**Note:** These are simplified instructions for common SBCs, to get you going quickly. denko-piboard can be congigured for any SoC with hardware support in Linux. See [the board maps readme](board_maps/README.md).

### Raspberry Pi 4 and Below
- For Raspberry Pi OS specifically
- Save the [default map](board_maps/raspberry_pi.yml) as `~/.denko_piboard_map.yml` on your board.
- Add the lines below to `/boot/config.txt`, and reboot.

```
# 2 PWMS on GPIO 12 and 13
dtoverlay=pwm-2chan,pin=12,func=4,pin2=13,func2=4
# /dev/i2c-1 (I2C1) @ 400 kHz
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=400000
# /dev/spidev0.0 (SPI0) with first chip select (CS0) enabled
dtoverlay=spi0-1cs
```

### Orange Pi Zero 2W
- For DietPi OS specifically
- 2 PWMs on GPIO 226 and 227 (not matching the docs) are enabled without any setup.
- Save the [default map](board_maps/orange_pi_zero_2w.yml) as `~/.denko_piboard_map.yml` on your board.
- Add/edit the lines below in `/boot/dietpiEnv.txt`, and reboot.

```
# /dev/i2c-3 (I2C3) @ 100 kHz
# /dev/spidev1.0 (SPI1) with first chip select (CS0) enabled
overlay_prefix=sun50i-h616
overlays=i2c1-pi spidev1_0
```

## Get Permissions
By default, only the Linux `root` user can use GPIO / I2C / SPI / PWM. If you have a default board map at `~/.denko_piboard_map.yml`, save [this script](scripts/set_permissions.rb) to your SBC, then run it:

```console
ruby set_permissions.rb
```

It will load load the default board map, then:
- Create any necessary Linux groups
- Add your user to the relevant groups
- Change ownership and permissions for devices in the map, so you can read/write them

**Note:** `sudo` is required.

**Note:** If you automate this script to run at boot (recommended), it will run as root. Set the `USERNAME` constant to your Linux user's name as a String literal. This ensures the map loads from your home, and changes are applied to your user, not root.

## Modifying Examples From Main Gem
Some [examples](examples) are included in this gem, but the [main denko gem](https://github.com/denko-rb/denko/tree/master/examples) is more comprehensive. Those are written for connected microcontrollers, `Denko::Board`, but can be modified for `Denko::PiBoard`:

1. Replace setup code:
  ```ruby
    # Replace this:
    require 'bundler/setup'
    require 'denko'
    # With this:
    require 'denko/piboard'

    # Replace this:
    board = Denko::Board.new(Denko::Connection::Serial.new)
    # With this:
    board = Denko::PiBoard.new
  ```

2. Change pin numbers and I2C/SPI device indices as needed.
