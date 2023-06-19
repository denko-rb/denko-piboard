# dino-piboard 0.13.0

### Raspberry Pi GPIO in Ruby

This gem adds support for the Raspberry Pi GPIO interface to the [`dino`](https://github.com/austinbv/dino) gem. Unlike the main gem, which requires an external microcontroller, this lets you to connect peripherals directly to the Pi.

`Dino::PiBoard` is a drop-in replacement for `Dino::Board`, which would represent a connected micrcontroller. Everything maps to the Pi's built-in GPIO pins instead.

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
#### More Examples
Some Pi-specific code is shown in this gem's [examples](examples) folder, but most examples are in the [main gem](https://github.com/austinbv/dino/tree/master/examples). They must be modified to work with the Pi's GPIO:

1. Replace setup code:
  ```ruby
    # Replace this:
    require 'bundler/setup'
    require 'dino'
    # With this:
    require 'dino/piboard'

    # Replace this:
    connection = Dino::Connection::Serial.new()
    board = Dino::Board.new()
    # With this:
    board = Dino::PiBoard.new
  ```

2. Update GPIO/pin numbers as needed. Raspberry Pi pinouts can be found [here](https://pinout.xyz/).
  
**Note:** Not all features from all examples are implemented yet, nor can be implemented. See [Features](#features) below.

## Installation
This gem depends on the [pigpio library](https://github.com/joan2937/pigpio) and [pigpio gem](https://github.com/nak1114/ruby-extension-pigpio), which provides Ruby bindings, as well as [libgpiod](https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git).

#### 1. Install pigpio and libgpiod packages
```shell
sudo apt install pigpio libgpiod-dev
```

#### 2. Install pigpio gem
The `pigpio` gem has a couple bugs. Until fixes are merged, please install from [this fork](https://github.com/vickash/ruby-extension-pigpio):
```shell
git clone https://github.com/vickash/ruby-extension-pigpio.git
cd ruby-extension-pigpio
gem build
gem install ruby-extension-pigpio-0.1.11.gem
```

#### 3. Install dino gem
This gem is very new. It __will not__ work with the version of `dino` (0.11.3) currently available from RubyGems. Install the latest version (future 0.13.0) from the master branch instead:
```shell
git clone https://github.com/austinbv/dino.git
cd dino
git submodule init
git submodule update
gem build
gem install dino-0.13.0.gem
```

#### 4. Install dino/piboard gem
Again, since this gem is so new, install from the latest master branch:
```shell
git clone https://github.com/dino-rb/dino-piboard.git
cd dino-piboard
gem build
gem install dino-piboard-0.13.0.gem
```

**Note:** `sudo` may be needed before `gem install` if using the preinstalled Ruby on a Raspberry Pi.

## Pi Setup
Depending on your Pi setup, libgpiod may limit GPIO access to the `root` user. If this is the case, Ruby scripts will fail with a `libgpiod` error. To give your user account permission to access GPIO, add it to the `gpio` group.
```
sudo usermod -a -G gpio YOUR_USERNAME
```

I2C, SPI and the hardware UART are disabled on the Pi by default. Enable them with the built in utility:
```shell
sudo raspi-config
```

Select "Interfacing Options" from the menu and enable as needed. More info in the [Features](#features) section.

#### pigpiod
The `pigpio` package includes `pigpiod`, which runs in the background as root, providing GPIO access. Ruby scripts won't work if it isn't running. You should only need to start it once per boot. You can automate it, or start manually with:
```shell
sudo pigpiod -s 10
```

**Note:** `-s 10` sets `pigpiod` to tick every 10 microseconds, lowering CPU use. Valid values are: 1, 2, 4, 5, 8, 10 (5 default).

## Features

### Already Implemented
  - Internal Pull Down/Up
  - Digital Out
  - Digital In
  - PWM Out (use on any pin disables PCM out, cancels Servo on same pin)
  - Servo   (use on any pin disables PCM out, cancels PWM Out on same pin)
  - ToneOut (uses waves, one at a time per board, cancels any Infrared Out)
  - I2C
    - Must enable with `raspi-config` before use. Instructions [here](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c).
    - I2C hardware clock cannot be set dynamically, like a microcontroller. Must set in `/boot/config.txt`. Default is 100 kHz. 400 kHz recommended if transferring a lot of data, like with SSD1306 OLED. See [here](https://www.raspberrypi-spy.co.uk/2018/02/change-raspberry-pi-i2c-bus-speed/) for instructions.
  - DHT Class Temperature + Humidity Sensors

### Partially Implemented
  - SPI
    - Must enable with `raspi-config` before use. Insturctions [here](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-spi).
    - Only Uses SPI1 interface, not SPI0.
    - Does not bind CE pins according to GPIO pinout. Any pin can be used for chip enable.
    - SPI modes 1 and 3 may not work.
    - No listeners yet.

### To Be Implemented
  - OneWire
  - Infrared Out
  - Hardware UART
  - BitBang I2C
  - BitBang SPI 
  - BitBang UART
  - WS2812

### Differences
  - Listeners are still polled in a thread, but always at 1ms.
  - pigpio has very fast native input callbacks available, but events are not received in order on a global basis, only per pin. This creates issues where event order between pins is important (like a RotaryEncoder). May expose this functionality for SinglePin components later.

### Incompatible
  - EEPROM (Use the filesystem for persistence instead)
  - Analog IO (No analog pins on Raspberry Pi. Use ADC or DAC over I2C or SPI)
