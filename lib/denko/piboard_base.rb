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
      @gpio_dev = gpio_chip
      @i2c_devs = [i2c_devices].flatten.compact
      @spi_devs = [spi_devices].flatten.compact

      # Config state for each pin.
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
