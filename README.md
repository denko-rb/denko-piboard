# denko-piboard 0.14.0

Use the GPIO features of Linux single board computers in Ruby. Hardware support is provided by [lgpio](https://github.com/denko-rb/lgpio), while drivers and higher-level features come from [denko](https://github.com/denko-rb/denko). This gem brings them together.

`Denko::PiBoard` (your SBC) becomes a drop-in replacement for `Denko::Board` (a microcontroller).

## Example
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
  - Much faster than microcontroller 1ms polling
  - Less affected by long-running calls compared to microcontrollers. Eg. Infrared or WS2812
  - Alerts read from a FIFO queue of up to 65,536. Oldest alerts lost first.
- [x] Software PWM Out (any pin)
- [x] Hardware PWM Out (specific pins per board)
- [x] Tone Out (via Software PWM or Hardware PWM)
- [x] Servo (via Hardware PWM)
- [x] Infrared Out (via Hardware PWM)
- [x] Hardware I2C
  - [x] Multiple interfaces. Give `index: N` to `#new`, where N is from `/dev/i2c-N`.
- [x] Hardware SPI
  - [x] Multiple interfaces. Give `index: N` to `#new`, where N is from `/dev/spidevN.0`.
  - [x] WS2812 addressable LED via SPI MOSI
  - [ ] SPI Listeners from `denko`
  - **Note**: SPI devices should only bind the `CS0` select pin. Binding more excludes them from use as regular GPIO without unbinding and rebooting. `PiBoard` can use any GPIO as a SPI select pin.
- [ ] UART
- [x] Ultrasonic Input (for HC-SR04 and similar)
- [x] Pulse Sequence Input (for DHT enviro sensors and similar)
- [x] Bit-Bang I2C
- [x] Bit-Bang SPI
- [x] Bit-Bang 1-Wire

### Incompatible Features (from denko)
- EEPROM
  - Use filesystem for persistence instead
- Analog I/O
  - No ADCs or DACs built into these SBCSs
  - External ones will work over I2C or SPI

## Support

#### Hardware

:green_heart: Known working
:heart: Awaiting testing
:question: Might work. No hardware

|    Chip           | Status          | Products                               | Notes |
| :--------         | :------:        | :----------------------                |------ |
| Allwinner H618    | :green_heart:   | Orange Pi Zero 2W                      |
| Rockchip RK3566   | :green_heart:   | Radxa Zero 3W/E, Radxa Rock 3C         | Armbian, Kernel 6.1.75-vendor-rk35xx
| BCM2835           | :green_heart:   | Raspberry Pi 1, Raspberry Pi Zero (W)  |
| BCM2836/7         | :question:      | Raspberry Pi 2                         |
| BCM2837A0/B0      | :green_heart:   | Raspberry Pi 3                         |
| BCM2711           | :green_heart:   | Raspberry Pi 4, Raspberry Pi 400       | Raspberry Pi OS, Kernel 6.6.47-v8+
| BCM2710A1         | :green_heart:   | Raspberry Pi Zero 2W                   |
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

# Temporary fork of: wget https://github.com/joan2937/lg/archive/master.zip
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

**Note:** The first two sections describe how to configure `denko-piboard` for any Linux SBC. If you have one of pre-configured boards (see [board_maps](examples/board_maps)), and want the default configuration, you can skip to the instructions for your SBC below.

### Overlays

The physical pins on your SBC can internally connect (multiplex) to diffent hardware devices within the SoC. The default is a regular GPIO. To use hardware PWM, I2C and SPI, we use Linux device tree overlays. These reserve pins, disconnected them from GPIO, and connect them to these devices instead.

This happens at boot, so there are side-effects:
- Pins reserved by I2C or SPI cannot be used for anything else, until the interface is disabled, and the SBC is rebooted.
- `denko-piboard` does some abstraction that lets a hardware PWM to work as a regular GPIO, but **only for digital output**, and it is significantly slower.
- I2C frequency cannot be changed on a per-transmission basis.

There are a couple other issues too:
- A single SoC can implement multiple `/dev/gpiochip*` devices, with usable GPIOs spread across multiple chips, and non-unque line numbers.
- Once PWM is enabled for a pin, it needs to be called by its `pwmchip*` and `pwm*` channel, not its regular GPIO number.
- I2C and SPI devices reserve pins, but we refer to them by their index (N) from `/dev/spidev-N.0` or `/dev/i2c-N`.

To deal with all this complexity, and standardize the user interface, `denko-piboard` uses board maps.

### Board Maps

A board map is a YAML file that outlines all the GPIO, PWM, I2C and SPI resources that exist (and are enabled) for a particular SBC.

It follows these conventons:
- `Denko::PiBoard.new` will raise unless it has a board map.
- It accepts a board map file path as its only argument\
- If that isn't given, it looks for `.denko_piboard_map.yml` in the user's home directory.
- In the map, individual GPIOs are referred to, and keyed by, their "friendly" / human-readable" numbers
  - These are arbitrary in theory, but the rule of thumb is: "unique numbers shown in the SBC's documentation"
  - These are NOT physical numbers on the pinout
  - These are NOT **necessarily** (although they often match) the line numbers of `/dev/gpiochip*` instances, since those may be non-unique
- Each GPIO number declares its:
  - Linux gpiochip
  - Line on that gpiochip
  - Physical number on the SBC's pinout (optional)
- Each PWM declares:
  - Which GPIO it takes when enabled
  - Its Linux pwmchip
  - Its pwm channel on that chip
- Each I2C or SPI interface declares:
  - All the GPIO numbers it takes, keyed to their names, eg. "miso:", "sda:" etc.

Using this information, `denko-piboard`:
- Refers to GPIOs by a single, user-friendly, unique number (rather than a tuple of gpiochip and line)
- Refers to PWMs by the by the GPIO number they multiplex with (rather than a tuple of pwmchip and channel)
- Refers to I2C and SPI by their Linux device indices
- Raises errors if you try to use a reserved pin. This would fail silently otherwise, which can be very confusing.

Using this, overlay documentation for your board, and the examples in `examples/board_maps`, you should be able to create a map for any board that works now.

### Raspberry Pi 4 and Below
Default board map: `examples/board_maps/raspberry_pi.yml`
Add these lines to `/boot/config.txt` and reboot.
```console
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
