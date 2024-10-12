# Creating Custom Board Maps

You will need:
- Your SBC, running a recent (5.10 kernel or later) Linux distribution
- A working understanding of how to enable/disable device tree overlays in Linux
- Documentation for your board, specifically:
  - Its pinout, with "friendly" GPIO numbers
  - Which GPIO numbers correspond to which device tree overlays

## Overlays

The physical pins on your SBC can internally connect to diffent hardware devices within the SoC. The default is regular GPIO. To use hardware PWM, I2C and SPI, Linux device tree overlays tell the kernel to reserve pins, disconnected them from GPIO, and connect them to the other hardware instead.

This happens at boot, so there are side-effects:
- Pins reserved by I2C or SPI can't be used for GPIO, unless the interface is disabled, and the SBC rebooted.
- With some asbraction tricks, a PWM can work as a regular GPIO, but **for digital output only**, and it's slower.
- I2C frequency can only be changed at boot time, not on a per-transmission basis.

There are a couple other issues too:
- One SoC may have GPIOs on multiple `/dev/gpiochip*`s, with non-unque line numbers.
- PWM is called by its `pwmchip*` and `pwm*` channel, not GPIO number.
- I2C and SPI are called by index (N) from `/dev/i2c-N` or `/dev/spidev-N.0`, not GPIO numbers.

To deal with this complexity, and standardize the user interface, denko-piboard uses board maps.

## Board Maps

A board map is a YAML file, defining all the GPIO, PWM, I2C and SPI resources enabled on the SBC.

It follows these conventons:
- `Denko::PiBoard.new` will raise unless it finds a board map
- It accepts a board map file path as its only argument
- If that isn't given, it looks for `.denko_piboard_map.yml`, in the user's home directory.
- In the map, individual GPIOs are referred to (keyed by) their "friendly" or human-readable" numbers
  - Theoretically arbitrary, but rule of thumb is: "unique numbers from the SBC's documentation"
  - These are NOT physical pin numbers from the pinout
  - These might match, but are NOT necessarily `/dev/gpiochip*` line numbers. Those can be non-unique, if multiple gpiochips.
- Each GPIO number declares its:
  - Linux gpiochip
  - Line on that gpiochip
  - Physical number on the SBC's pinout (optional)
- Each PWM declares:
  - Which GPIO number it reserves when enabled (this is its key)
  - Its Linux pwmchip
  - Its pwm channel on that chip
- Each I2C or SPI interface declares:
  - Its index, N from `/dev/i2c-N` or `/dev/spidev-N.0` (this is its key)
  - All the GPIO numbers it reserves, keyed to their names. Eg. `miso:`, `sda:` etc.

This information enables denko-piboard to:
- Refer to GPIOs by a single, user-friendly, unique number (rather than a tuple of gpiochip and line)
- Refer to PWMs by the GPIO number they multiplex with (rather than a tuple of pwmchip and channel)
- Refer to I2C and SPI by their Linux device indices
- Raise errors if you try to use any reserved pin. This fails silently otherwise, which is confusing.

There are pre-made maps for some boards [here](board_maps), which can be followed as templates. In general, these enable:
- 2 PWM pins
- 1 I2C interface (on physical pins 3,5 when possible)
- 1 SPI interface (on physical pins 19,21,23 when possible)
