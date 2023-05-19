# dino-piboard 0.13.0

### Raspberry Pi GPIO in Ruby

This gem adds support for the Raspberry Pi GPIO interface to the [`dino`](https://github.com/austinbv/dino) gem. Unlike the main gem, which uses an external microcontroller connected to a computer, this lets you to connect peripherals directly to the Pi.

`Dino::PiBoard` is a drop-in replacement for `Dino::Board`, which would represent a micrcontroller. Everything maps to the Pi's built-in GPIO pins instead.

**Note:** This is not for the Raspberry Pi Pico (W) / RP2040. That microcontroller works with the main gem.

## Example
Create a script, `led_button.rb`:

```ruby
require 'dino/piboard'

# Board instance for the Pi.
board = Dino::PiBoard.new

# LED connected to GPIO4.
led = Dino::LED.new(board: board, pin: 4)

# Momentary button connected to GPIO17, using internal pullup.
button = Dino::DigitalIO::Button.new(board: board, pin: 17, pullup: true)

# Led on when button is down (0)
button.down do
  puts "Button down"
  led.on
end

# Led is off when button is up (1)
button.up do
  puts "Button up"
  led.off
end

# Sleep main thread. Ctrl+C to quit.
sleep
```

Run it:
```shell
ruby led_button.rb
```
#### Modifying Examples
The main gem has many [examples](https://github.com/austinbv/dino/tree/master/examples), but they need to be modified slightly to work with the Pi's GPIO:
  - Find the line where the variable `board` is set. It should look like `board = Dino::Board.new`.
  - Remove all code up to, and including, that line. Replace it with:
    ```ruby
    require 'dino/piboard'
    board = Dino::PiBoard.new
    ```
  - Update GPIO (pin) numbers as needed. Raspberry Pi pinouts can be found [here](https://pinout.xyz/).
  
**Note:** Not all features from all examples are implemented yet, nor can be implemented. See [Features](#features) below.

## Installation
This gem uses the [`pigpio`](https://github.com/joan2937/pigpio) C library and [`pigpio`](https://github.com/nak1114/ruby-extension-pigpio) gem which provides Ruby bindings.  

This gem is very new. It __will not__ work with the version of `dino` (0.11.3) currently available from RubyGems. Install the latest version (future 0.13.0) from the master branch instead:
```shell
git clone https://github.com/austinbv/dino.git
cd dino
gem build
gem install dino-0.13.0.gem
```

Install pigpo C library:
```shell
sudo apt-get install pigpio
```

The `pigpio` Ruby gem has a couple known bugs. Until pull requests with fixes are merged, please install from [this fork](https://github.com/vickash/ruby-extension-pigpio):
```shell
git clone https://github.com/vickash/ruby-extension-pigpio.git
cd ruby-extension-pigpio
gem build
gem install ruby-extension-pigpio-0.1.11.gem
```

Finally, install this gem:
```shell
gem install dino-piboard
```

**Note:** Add `sudo` before `gem install` if using the system Ruby. Rubies from [`rbenv`](https://github.com/rbenv/rbenv) won't need it.

## Pi Setup
I2C, SPI and the hardware UART are disabled on the Pi by default. Enable them with the built in utility:
```shell
sudo raspi-config
```

Select "Interfacing Options" from the menu and enable as needed. More info in the [Features](#features) section.

#### pigpiod
The `pigpio` C library includes `pigpiod`, which runs in the background as root, providing GPIO access. Ruby scripts won't work if it isn't running. You should only need to start it once per boot. You can script it to start automatically, or start it manually with:

```shell
sudo pigpiod -s 10
```

**Note:** `-s 10` sets `pigpiod` to tick every 10 microseconds. Valid values are: 1, 2, 4, 5, 8, 10 (5 default).

## Features

### Already Implemented
  - Internal Pull Down/Up
  - Digital Out
  - Digital In
  - PWM Out (use on any pin disables Pi's analog audio out, cancels Servo on same pin)
  - Servo   (use on any pin disables Pi's analog audio out, cancels PWM Out on same pin)
  - ToneOut (uses waves, one at a time per board, cancels any Infrared Out)
  - I2C
    - Must enable with `raspi-config` before use. Instructions [here](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c).
    - I2C hardware clock cannot be set dynamically, like a microcontroller. Must set in `/boot/config.txt`. Default is 100 kHz. 400 kHz recommended if transferring a lot of data, like with SSD1306 OLED. See [here](https://www.raspberrypi-spy.co.uk/2018/02/change-raspberry-pi-i2c-bus-speed/) for instructions.

### Partially Implemented
  - SPI
    - Must enable with `raspi-config` before use. Insturctions [here](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-spi).
    - Only Uses SPI1 interface, not SPI0.
    - Does not bind CE pins according to GPIO pinout. Any pin can be used for chip enable.
    - SPI modes 1 and 3 may not work.
    - No listeners yet.

### To Be Implemented
  - SPI BitBang
  - OneWire
  - Infrared Out
  - WS2812
  - Bitbang UART
  - DHT Temperature

### Won't Be Implemented
  - Hardware UART. It would wrap a [`rubyserial`](https://github.com/hybridgroup/rubyserial) instance. Use that directly instead.

### Might Be Different
  - Variable Digital Listen Timing (pigpio doesn't have a real way to do this, but glitch filter might be even better?)

### Incompatible
  - Handshake (no need, since running on the same board)
  - EEPROM (can't mess with that. Use the filesystem instead)
  - Analog IO (No analog pins on Raspberry Pi. Use an ADC or DAC over I2C or SPI)
