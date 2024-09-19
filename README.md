# denko-piboard 0.14.0

Use GPIO, I2C, SPI and PWM features of a Linux single-board-computer in Ruby. Hardware support is provided by [`lgpio`](https://github.com/denko-rb/lgpio). Drivers and higher-level features come from [`denko`](https://github.com/denko-rb/denko). This gem brings them together.

`Denko::PiBoard` (your SBC) becomes a drop-in replacement for `Denko::Board` (a microcontroller).

## Example
```ruby
# Example to turn a LED on when a button is held down, off when released.

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
- [x] Internal Pull Up/Down
- [x] Open Drain/Source
- [x] Digital Read/Write
- [x] Digital Listen (Alerts)
  - Much faster than microcontroller 1ms polling
  - Less affected by long-running calls compared to microcontrollers. Eg. Infrared or WS2812
  - Alerts read from a FIFO queue of up to 65,536. Oldest alerts lost first.
- [x] Software PWM Out (any pin)
- [x] Hardware PWM Out (specific pins per board)
- [x] Tone Out (via Software PWM or Hardware PWM)
- [x] Servo (via Hardware PWM)
- [x] Infrared Out (via Hardware PWM)
- [x] Hardware I2C
  - [ ] > 1 interface
- [x] Hardware SPI
  - [ ] > 1 interface
  - [x] WS2812 addressable LED via SPI MOSI
  - [ ] SPI Listeners from `denko`
  - **Note**:  Let SPI interfaces bind the `CS0` select pin and no others. Bound select pins cannot be used as regular GPIO, and bindings cannot be changed without rebooting. `PiBoard` can use `CS0` (give the associated GPIO number) **OR** any arbitrary GPIO as a SPI select pin.
- [ ] UART
- [x] Ultrasonic Input (for HC-SR04 and similar)
- [x] Pulse Sequence Input (for DHT enviro sensors and similar)
- [x] Bit-Bang I2C
- [ ] Bit-Bang SPI
- [x] Bit-Bang 1-Wire

### Incompatible Features From `denko`
- EEPROM (Use the filesystem for persistence instead)
- Analog I/O (No ADCs or DACs integrated into these SBCSs. Use extenal ADC or DAC)

## Support

#### Hardware

:green_heart: Known working
:heart: Awaiting testing
:question: Might work. No hardware

|    Chip           | Status          | Products                               | Notes |
| :--------         | :------:        | :----------------------                |------ |
| Allwinner H618    | :green_heart:   | Orange Pi Zero 2W                      |
| Rockchip RK3566   | :heart:         | Radxa Zero 3W, Radxa Rock 3C           |
| BCM2835           | :green_heart:   | Raspberry Pi 1, Raspberry Pi Zero (W)  |
| BCM2836/7         | :question:      | Raspberry Pi 2                         |
| BCM2837A0/B0      | :green_heart:   | Raspberry Pi 3                         |
| BCM2711           | :green_heart:   | Raspberry Pi 4, Raspberry Pi 400       |
| BCM2710A1         | :green_heart:   | Raspberry Pi Zero 2W                   |
| BCM2712           | :question:      | Raspberry Pi 5                         |

#### Software

- Operating Systems:
  - DietPi (Bookworm)
  - Raspberry Pi OS (Bookworm) | Kernel 6.6.47-v8+

- Rubies:
  - Ruby 3.3.5 +YJIT

**Note:** The latest Ruby with YJIT is always recommended for performance, but any 3.0+ should work.

## Installation

#### 1. Install the lg C library
```shell
sudo apt install swig python3-dev python3-setuptools

wget https://github.com/vickash/lg/archive/refs/heads/master.zip
unzip master.zip
cd lg-master
make
sudo make install
```

#### 2. Install denko-piboard gem
```shell
gem install denko-piboard
```
**Note:** `sudo` may be needed before `gem install` if using the system Ruby.

## Hardware Configuration

### 1. Enable I2C, SPI and PWM Devices
I2C, SPI and PWM may be disabled on your SBC by default. This varies by manufacturer and Linux distro, but most distros include a config utility.

For the Orange Pi Zero 2W specifically, running DietPi, I wrote a guide [here](http://vickash.com/2024/08/06/ruby-lgpio-on-orangepi-zero2w.html#step-5-enable-i2c-and-spi).

For Raspberry Pi SBCs, running Raspberry Pi OS, `sudo raspi-config` should have most settings available, inside `Interfacing Options`. See also:
  - [Configuring I2C](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c) (Adafruit)
  - [Configuring SPI](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-spi) (Adafruit)
  - [Change Raspberry Pi I2C Bus Speed](https://www.raspberrypi-spy.co.uk/2018/02/change-raspberry-pi-i2c-bus-speed/) (Raspberry Spy)
  - [Raspberry Pi Pinout](https://pinout.xyz/)

**Note:** I2C frequency is set at boot time in Linux, and cannot be changed on a per-transmission basis.

**Note:** Pins bound to an I2C, SPI or UART interface cannot be used for Digital I/O at all.

**Note:** Once Hardware PWM is used on a given pin, that pin cannot be used for Digital I/O again, until reboot.

### 2. Get Permission
By default, only `root` might have access to GPIO / I2C / SPI / PWM. If you don't want to run Ruby scripts as `root`, [this section](http://vickash.com/2024/08/06/ruby-lgpio-on-orangepi-zero2w.html#step-6-get-permission) of my Orange Pi tutorial should work for any setup.

## More Examples
There are Linux specific examples [here](examples), but [main gem examples](https://github.com/denko-rb/denko/tree/master/examples) can be modified to work too:

1. Replace setup code:
  ```ruby
    # Replace this:
    require 'bundler/setup'
    require 'denko'
    # With this:
    require 'denko/piboard'

    # Replace this:
    connection = Denko::Connection::Serial.new()
    board = Denko::Board.new()
    # With this:
    board = Denko::PiBoard.new
  ```

2. Update pin numbers as needed.

3. For hardware I2C, SPI and PWM to work, you must give a YAML map of your board as the only argument to `Denko::PiBoard.new`. See [this example](examples/board_maps/orange_pi_zero_2w.yml) for the Orange Pi Zero 2W, and modify to match your board.

**Note:** Currently this gem and the main `denko` gem only support 1 each of I2C and SPI hardware interfaces.

**Note:** Not everything in the main gem is implemented yet, nor can be implemented. See [Features](#features).
