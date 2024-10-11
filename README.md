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

**Note:** The first two sections describe how to configure `denko-piboard` for any Linux SBC. For some popular boards, there are simplified instructions below.

### Overlays

The physical pins on your SBC can internally connect to diffent hardware devices within the SoC. The default is regular GPIO. To use hardware PWM, I2C and SPI, we use Linux device tree overlays. These let the kernel reserve pins, disconnected them from GPIO, and connect them to the other hardware instead.

This happens at boot, so there are side-effects:
- Pins reserved by I2C or SPI can't be used for GPIO, unless the interface is disabled, and the SBC rebooted.
- `denko-piboard` does some abstraction to let hardware PWMs work as regular GPIO, but **only for digital output**, and it is significantly slower.
- I2C frequency can only be changed at boot time, not on a per-transmission basis.

There are a couple other issues too:
- One SoC may have multiple `/dev/gpiochip*`s, with GPIOs across multiple chips, and non-unque line numbers.
- PWM is called by its `pwmchip*` and `pwm*` channel, not GPIO number.
- I2C and SPI are called by index (N) from `/dev/i2c-N` or `/dev/spidev-N.0`, not GPIO numbers.

To deal with this complexity, and standardize the user interface, `denko-piboard` uses board maps.

### Board Maps

A board map is a YAML file that outlines all the GPIO, PWM, I2C and SPI resources that exist (and are enabled) for a particular SBC.

It follows these conventons:
- `Denko::PiBoard.new` will raise unless it finds a board map
- It accepts a board map file path as its only argument
- If that isn't given, it looks for `.denko_piboard_map.yml` in the user's home directory.
- In the map, individual GPIOs are referred to (and keyed by) their "friendly" or human-readable" numbers
  - These are arbitrary in theory, but the rule of thumb is: "unique numbers shown in the SBC's documentation"
  - These are NOT physical numbers on the pinout
  - These are NOT **necessarily** (although they often match) the line numbers of `/dev/gpiochip*` instances, since those may be non-unique
- Each GPIO number declares its:
  - Linux gpiochip
  - Line on that gpiochip
  - Physical number on the SBC's pinout (optional)
- Each PWM declares:
  - Which GPIO number it reserves when enabled
  - Its Linux pwmchip
  - Its pwm channel on that chip
- Each I2C or SPI interface declares:
  - All the GPIO numbers it reserves, keyed to their names, eg. "miso:", "sda:" etc.

This information, enables `denko-piboard` to:
- Refer to GPIOs by a single, user-friendly, unique number (rather than a tuple of gpiochip and line)
- Refer to PWMs by the GPIO number they multiplex with (rather than a tuple of pwmchip and channel)
- Refer to I2C and SPI by their Linux device indices
- Raise errors if you try to use a reserved pin. This fails silently otherwise, which is confusing.

There are preconfigured maps, for some popular boards, located [here](examples/board_maps). In general, these enable:
- 2 PWM pins
- 1 I2C interface (preferably on physical pins 3,5)
- 1 SPI interface (preferably on physical pins 19,21,23)

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
