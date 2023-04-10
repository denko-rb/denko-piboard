# dino-piboard 0.13.0

### Raspberry Pi GPIO and Peripherals in Ruby

This gem adds support for the Raspberry Pi's GPIO interface and perhipherals to [`dino`](https://github.com/austinbv/dino). Unlike the main gem, which connects a computer running Ruby to an external microcontroller, this lets you to connect hardware directly to the Pi, skipping the microcontroller in between.

Using the [`pigpio`](https://github.com/nak1114/ruby-extension-pigpio) gem, and [`pigpio`](https://github.com/joan2937/pigpio) C library, `Dino::PiBoard` is a drop-in replacement for `Dino::Board`, which would represent the micrcontroller. Everything maps to the Pi's built-in GPIO instead.

**Note:** This is not for the Raspberry Pi Pico (W) / RP2040. That microcontroller is covered by the main gem.

## Example
Create a script, `led_button.rb`:
```ruby
require 'dino/piboard'

# Create a board instance for the Raspberry Pi.
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

Run the script:
```shell
ruby led_button.rb
```

Check out the [`examples`](https://github.com/austinbv/dino/tree/master/examples) folder in the main gem for more. To adapt those examples:
  - Find the line where the variable `board` is set. It should look something like `board = Dino::Board.new`.
  - Remove all code up to, and including, that line. Replace it with:
    ```ruby
    require 'dino/piboard'
    board = Dino::PiBoard.new
    ```
  - Update pins as necessary. Many of the GPIOs will be different, I2C bus will need the correct SDA pin (2 for all Pis), etc.
  
**Note:** Not all features are implemented yet, nor can be implemented. See [Feautres](#features) below.

## Installation

This gem is very new. It WILL NOT work with the version of `dino` (0.11.3) currently available from RubyGems. Before installing `dino-piboard`, make sure to install the latest `dino` (future 0.13.0) from the master branch.

Install dino from source:
```shell
gem uninstall dino
git clone https://github.com/austinbv/dino.git
cd dino
gem build
gem install dino-0.13.0.gem
```

Install pigpo C library:
```shell
sudo apt-get install pigpio
```

Install pigpio gem:
```shell
gem install pigpio
```

**Note:** This might not work on Ruby 3+. If it doesn't, install from [this fork](https://github.com/vickash/ruby-extension-pigpio) until fixes are merged:
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

**Note:** Add `sudo` before `gem install` and `gem uninstall` if using the system Ruby preinstalled on the Pi. Rubies installed with [`rbenv`](https://github.com/rbenv/rbenv) shouldn't require it.

## Pi Setup

I2C, SPI and the hardware UART are disabled on the Pi by default. Enable them with the built in utility:
```shell
sudo raspi-config
```
Select "Interfacing Options" from the menu and enable as needed. More info in the [Features](#features) section.

#### pigpiod

The `pigpio` package includes `pigpiod`, which runs in the background as root, providing GPIO access. Ruby scripts won't work if it isn't running. It should only need to be started once per boot. You can script it to start automatically, or start it manually with:
```shell
sudo pigpiod -s 10
```
**Note:** `-s 10` tells `pigpiod` to tick every 10 microseconds (maximum), reducing CPU usage. Default is 5.

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

### Partially Implemented
  - SPI
    - Must enable with `raspi-config` before use. Insturctions [here](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-spi).
    - Only Uses SPI1 interface, not SPI0.
    - Does not bind CE pins according to GPIO pinout. Any pin can be used for chip enable.
    - SPI modes 1 and 3 may not work.
    - No listeners yet.

### To Be Implemented
  - Bitbang Shift In / Shift Out / SPI
  - OneWire
  - Infrared Out
  - WS2812
  - Bitbang UART

### Won't Be Implemented
  - Hardware UART. It would wrap a [`rubyserial`](https://github.com/hybridgroup/rubyserial) instance. Use that directly instead.

### Might Be Different
  - Variable Digital Listen Timing (pigpio doesn't have a real way to do this, but glitch filter might be even better?)

### Incompatible
  - Handshake (no need, since running on the same board)
  - EEPROM (can't mess with that. Use the filesystem instead)
  - Analog IO (No analog pins on Raspberry Pi. Use an ADC or DAC over I2C or SPI)
