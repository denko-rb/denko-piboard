# denko-piboard 0.14.0

### Linux SBC GPIO in Ruby

This gem adds support for Linux GPIO, I2C, and SPI devices to the [`denko`](https://github.com/denko-rb/denko) gem. Unlike the main gem, peripherals are connected directly to a single board computer, such as a Raspberry Pi or Orange Pi, instead of a microcontroller attached to a computer.

`Denko::PiBoard`, representing your SBC GPIO header, is a drop-in replacement for `Denko::Board` (attached microcontroller).

**Note:** Development is being done on an Orange Pi Zero 2W. Examples will use its (somewhat unusual) GPIO numbers. Change these to suit your hardware, referring to its pinout diagram.

## Example
```ruby
require 'denko/piboard'

# Board instance for the Pi.
board = Denko::PiBoard.new

# LED connected to GPIO 260.
led = Denko::LED.new(board: board, pin: 260)

# Momentary button connected to GPIO 259, using internal pullup.
button = Denko::DigitalIO::Button.new(board: board, pin: 259, pullup: true)

# Callback runs when button is down (0)
button.down do
  puts "Button down"
  led.on
end

# Callback runs when button is up (1)
button.up do
  puts "Button up"
  led.off
end

# Sleep main thread. Ctrl+C to quit.
sleep
```

#### More Examples
Some examples are in this gem's [examples](examples) folder, but examples from the [main gem](https://github.com/denko-rb/denko/tree/master/examples) can be modified to work too:

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

2. Update GPIO/pin numbers as needed. Raspberry Pi pinouts can be found [here](https://pinout.xyz/).

3. Give I2C or SPI device details to `Denko::PiBoard.new` as needed. For example, if you want the `PiBoard` instance to use `/dev/i2c-2`, and the SDA pin for that device is GPIO 29, initialize as follows:
  ```
    board = Denko::Board.new(i2c_devices: [{index: 2, sda: 29}])
  ```
  See I2C and SPI examples for more info.

**Note:** Currently this gem, and the main `denko` gem, only support 1 each of I2C and SPI hardware devices. Support for multiples is planned.

**Note:** Not all features from all examples in the main gem are implemented yet, nor can be implemented. See [Features](#features) below.

## Support

#### Hardware

:green_heart: Support verified
:question: Should work, but not verified

|    Chip        | Status          | Products                               | Notes |
| :--------      | :------:        | :----------------------                |------ |
| Allwinner H618 | :green_heart:   | Orange Pi Zero 2 W                     |
| BCM2835        | :green_heart:   | Raspberry Pi 1, Raspberry Pi Zero (W)  |
| BCM2836/7      | :question:      | Raspberry Pi 2                         |
| BCM2837A0/B0   | :green_heart:   | Raspberry Pi 3                         |
| BCM2711        | :green_heart:   | Raspberry Pi 4, Raspberry Pi 400       |
| BCM2710A1      | :green_heart:   | Raspberry Pi Zero 2W                   |
| BCM2712        | :question:      | Raspberry Pi 5                         |

#### Software

- Operating Systems:
  - DietPi (Bookworm)

- Rubies:
  - Ruby 3.1.2 (system Ruby on DietPi)
  - Ruby 3.3.2 (with and without YJIT)

#### Dependencies

- [lg](https://github.com/joan2937/lg) C library
- [lgpio](https://github.com/denko-rb/lgpio) gem with Ruby bindings for C library
- [denko](https://github.com/denko-rb/denko) for main implementation

## Installation

#### 1. Install lg C library
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
This automatically installs dependency gems: `denko` and `lgpio`.

**Note:** `sudo` may be needed before `gem install` if using the system ruby.

## Hardware Setup

#### Enable I2C and SPI Devices
I2C and SPI may be disabled on the SBC by default. This varies by chip manufacturer and Linux distribution. You will need to figure out how to enable them on your machine.

For the Orange Pi Zero 2W specifically, running DietPi, I wrote a guide [here](http://vickash.com/2024/08/06/ruby-lgpio-on-orangepi-zero2w.html#step-5-enable-i2c-and-spi).

For Raspberry Pi SBCs, running Raspberry Pi OS, `sudo raspi-config` should have most settings available, inside `Interfacing Options`. See also:
  - [Configuring I2C](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c) (Adafruit)
  - [Configuring SPI](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-spi) (Adafruit)
  - [Change Raspberry Pi I2C Bus Speed](https://www.raspberrypi-spy.co.uk/2018/02/change-raspberry-pi-i2c-bus-speed/) (Raspberry Spy)

**Note:** Unlike microcontrollers used by the main gem, I2C frequency is set at boot time in Linux, and cannot be changed on a per-transmission basis.

### Get Permission
By default, only the `root` user might have access to GPIO, I2C and SPI devices. If you don't want to run your Ruby scripts as `root`, [this section](http://vickash.com/2024/08/06/ruby-lgpio-on-orangepi-zero2w.html#step-6-get-permission) of my Orange Pi Zero 2W setup tutorial is broadly applicable. It should give your user permissions, regardless of SBC or Linux distro in use.

## Features
- Internal Pull Down/Up
- Digital Out
- Digital In
  - Unlike the main gem, where the microcontroller polls pins as fast as every 1ms, `lgpio`'s alert feature reads them much faster.
- PWM Out (software timed, any pin)
- Tone Out (software timed, any pin)
- Servo (requires hardware PWM pin)
- Infrared Out (requires hardware PWM pin)
- I2C
  - Limited to 1 interface
- SPI
  - Limited to 1 interface
  - You should always setup the SPI interface to bind the `CE0` pin, and no others. Since these bindings cannot be changed without rebooting, this gem is written so it will use `CE0` if you give the corresponding GPIO number as your enable pin, but separately toggle any other GPIO to function as your enable pin, if needed. This way you bind the fewest pins possible to the SPI device, and leave them free for any use.
  - No listeners
- Pulse Sequence Input (for DHT-class temperature + humidity sensors)

### To Be Implemented
- Single Pulse Input (used for HC-SR04 sensor)
- OneWire (bit banged)
- BitBang I2C
- BitBang SPI
- WS2812 (over SPI only)
- UART

### Incompatible
- EEPROM (Use the filesystem for persistence instead)
- Analog IO (No ADCs or DACs integrated into these SBCSs. Use extenal ADC or DAC over I2C or SPI)
