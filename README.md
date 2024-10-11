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

## Features
- [x] Internal Pull-Up/Down
- [x] Open Drain/Source
- [x] Digital Read/Write
- [x] Digital Listen (Alerts)
  - Interrupt driven, unlike `denko` microcontroller 1ms polling
  - Built in software debounce (1us by default)
  - Alerts are read from a FIFO queue up to 65,536. Oldest alerts lost first.
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
- Analog I/O
  - No ADCs or DACs built into SBCs tested so far
  - External ones will work over I2C or SPI

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

## Installation

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
# The latest Ruby + YJIT from rbenv is best, but Ruby 3 from apt works too.
# sudo apt install ruby ruby-dev

gem install denko-piboard
```
**Note:** `sudo` may be needed before `gem install` if using the system Ruby.

## Enable Hardware

**Note:** These sections are simplified instructions for some common SBCs, but `denko-piboard` can be congigured for any SBC, as long as the hardware is supported by the relevant Linux subsystems. See [BOARD_MAPS.md](BOARD_MAPS.md).

### Instructions For Raspberry Pi 4 and Below
- Save the [default map](examples/board_maps/raspberry_pi.yml) to `~/.denko_piboard_map.yml` on your board.
- Add these lines to `/boot/config.txt` and reboot:
```
# PWM bound to GPIO 12 and 13
dtoverlay=pwm-2chan,pin=12,func=4,pin2=13,func2=4
# I2C1 @ 400 kHz
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=400000
# SPI0 with no reserved select pins
dtoverlay=spi0-0cs
```

### Get Permission
By default, only `root` might have access to GPIO / I2C / SPI / PWM. If you don't want to run Ruby scripts as `root`, [this section](http://vickash.com/2024/08/06/ruby-lgpio-on-orangepi-zero2w.html#step-6-get-permission) of my Orange Pi tutorial should work for any setup.

## More Examples
Specific [examples](examples) are provided for this gem, but [main gem examples](https://github.com/denko-rb/denko/tree/master/examples) can be modified to work:

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

2. Update pin numbers as needed.
