# denko-piboard 0.13.1

### Raspberry Pi GPIO in Ruby

This gem adds support for the Raspberry Pi GPIO interface to the [`denko`](https://github.com/denko-rb/denko) gem. Unlike the main gem, which requires an external microcontroller, this lets you to connect peripherals directly to the Pi.

`Denko::PiBoard` is a drop-in replacement for `Denko::Board`, which would represent a connected micrcontroller. Everything maps to the Pi's built-in GPIO pins instead, and Ruby runs on the Pi itself.

**Note:** This is not for the Raspberry Pi Pico (W) / RP2040. That microcontroller works with the main gem.

## Example
```ruby
require 'denko/piboard'

# Board instance for the Pi.
board = Denko::PiBoard.new

# LED connected to GPIO4.
led = Denko::LED.new(board: board, pin: 4)

# Momentary button connected to GPIO17, using internal pullup.
button = Denko::DigitalIO::Button.new(board: board, pin: 17, pullup: true)

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
Pi-specific examples are in this gem's [examples](examples) folder, but examples from the [main gem](https://github.com/denko-rb/denko/tree/master/examples) can be modified to work on the Pi:

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
  
**Note:** Not all features from all examples are implemented yet, nor can be implemented. See [Features](#features) below.

## Support

#### Hardware

:green_heart: Support verified
:question: Should work, but not verified

|    Chip        | Status          | Products              | Notes |
| :--------      | :------:        | :---------------      |------ |
| BCM2835        | :green_heart:   | Pi 1, Pi Zero (W)     |
| BCM2836/7      | :question:      | Pi 2                  |
| BCM2837A0/B0   | :green_heart:   | Pi 3                  |
| BCM2711        | :green_heart:   | Pi 4, Pi 400          |
| BCM2710A1      | :question:      | Pi Zero 2W            |

#### Software

- Operating Systems:
  - Raspberry Pi OS
  - DietPi
  
  Note: Both with kernel version 6.1 or higher.

- Rubies:
  - Ruby 2.7.4 (system Ruby on some Raspberry Pi OS installs)
  - Ruby 3.2.2 (with and without YJIT)
  - TruffleRuby 22.3.1 :man_shrugging: (Not available on ARMv6 Pis: Zero W, Pi 1. Not recommended in general)

#### Dependencies

- [pigpio](https://github.com/joan2937/pigpio)
- [libgpiod](https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git)
- [pigpio gem](https://github.com/nak1114/ruby-extension-pigpio) (Ruby bindings for pigpio)
- [denko](https://github.com/denko-rb/denko) (peripheral implementations from main gem)

## Installation

#### 1. Install pigpio and libgpiod packages
```shell
sudo apt install pigpio libgpiod-dev
```

#### 2. Install denko-piboard gem
```shell
gem install denko-piboard
```
This automatically installs dependency gems: `denko` and `pigpio`.

**Note:** `sudo` may be needed before `gem install` if using the Pi's system ruby.

## Pi Setup

#### pigpiod
The `pigpio` package installs `pigpiod`, which must run in the background (as root) for Ruby scripts to work. You should only need to start it once per boot. Automate it, or start manually with:
```shell
sudo pigpiod -s 10
```
**Note:** `-s 10` sets tick interval to 10 microseconds, lowering CPU use. Valid values are: 1, 2, 4, 5, 8, 10 (5 default).

#### libgpiod
Depending on your Pi and OS, `libgpiod` may limit GPIO access. If this happens, some scripts will fail. It is only used for digital read/write operations, so test with a simple script like blinking an LED. To get permission, add your user account to the `gpio` group:
```
sudo usermod -a -G gpio $(whoami)
```

#### Enable Features
I2C, SPI and the hardware UART may be disabled on the Pi by default. Enable them with the built-in utility:
```shell
# On Raspberry Pi OS:
sudo raspi-config

# On DietPi:
sudo dietpi-config
```
Select "Interfacing Options" (Raspberry Pi OS), or "Advanced Options" (DietPi) and enable features as needed.

## Features

### Already Implemented
  - Internal Pull Down/Up
  - Digital Out
  - Digital In
    - Listeners are polled in a thread, similar to a microcontroller, but always at 1ms.
    - `pigpio` supports even faster polling (1-10 microseconds), but events are not received in a consistent order across pins. Won't work for MultiPin components, but may implement for SinglePin.
  - PWM Out
  - Servo
  - Tone Out
  - Infrared Out
  - DHT Class Temperature + Humidity Sensors
  - I2C
    - Always uses I2C1 interface.
    - Must enable before use. Instructions [here](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c).
    - I2C clock cannot be set dynamically. It is set at boot time from `/boot/config.txt`. Default is 100 kHz. 400 kHz is recommended if higher data rate is needed, eg. using OLED screen. Instructions [here](https://www.raspberrypi-spy.co.uk/2018/02/change-raspberry-pi-i2c-bus-speed/).

### Partially Implemented
- SPI
  - Always uses SPI1 interface.
  - Must enable before use. Instructions [here](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-spi).
  - Does not bind CE pins according to GPIO pinout. Any pin can be used for chip enable.
  - SPI modes 1 and 3 may not work.
  - No listeners yet.

### Feature Exclusivity
- PWM Out / Servo Out
  - Using either of these on **any** pin disables the Pi's PCM audio output globally.

- Tone Out / Infrared Out
  - Both of these use pigpio's wave interface, which only has a single instance. Calling either on **any** pin automatically stops any running instance that exists. Both features can co-exist in a script, but cannot happen at the same time.

### To Be Implemented
  - OneWire
  - Hardware UART
  - BitBang I2C
  - BitBang SPI 
  - BitBang UART
  - WS2812

### Incompatible
  - EEPROM (Use the filesystem for persistence instead)
  - Analog IO (No analog pins on Raspberry Pi. Use ADC or DAC over I2C or SPI)
