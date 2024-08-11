require 'denko'
require 'lgpio'

module Denko
  class PiBoard
    LOW      = 0
    HIGH     = 1
    PWM_HIGH = 100
    def low;      LOW;      end
    def high;     HIGH;     end
    def pwm_high; PWM_HIGH; end

    def initialize(gpio_chip: 0, i2c_devices: nil, spi_devices: nil)
      # Validate GPIO, I2C and SPI devices.
      @gpio_dev = gpio_chip
      raise ArgumentError, "invalid gpio_chip: #{@gpio_dev} given. Must be Integer" if @gpio_dev.class != Integer

      @i2c_devs = [i2c_devices].flatten.compact
      @i2c_devs.each do |dev|
        raise ArgumentError, "invalid Integer pin for sda: in i2c_device: #{dev}" if dev[:sda].class != Integer
        raise ArgumentError, "invalid Integer for index: in i2c_device: #{dev}" if dev[:index].class != Integer
      end

      @spi_devs = [spi_devices].flatten.compact
      @spi_devs.each do |dev|
        raise ArgumentError, "invalid Integer pin for cs0: in spi_device: #{dev}" if dev[:cs0].class != Integer
        raise ArgumentError, "invalid Integer for index: in spi_device: #{dev}" if dev[:index].class != Integer
      end

      # Config state storage for pins.
      @pin_configs = []

      # This thread will receive alerts from the LGPIO process and call #update.
      @alert_thread = nil
      @reporting_started = false

      # Immediately open the GPIO device
      @gpio_handle = LGPIO.chip_open(@gpio_dev)
    end

    def finish_write
      LGPIO.chip_close(@gpio_handle)
    end

    #
    # Use standard Subcomponents behavior.
    #
    include Behaviors::Subcomponents

    def update(pin, message)
      if single_pin_components[pin]
        single_pin_components[pin].update(message)
      end
    end
  end
end
