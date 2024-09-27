require 'denko'
require 'lgpio'
require 'yaml'

module Denko
  class PiBoard
    LOW      = 0
    HIGH     = 1
    PWM_HIGH = 100
    def low;      LOW;      end
    def high;     HIGH;     end
    def pwm_high; PWM_HIGH; end

    attr_reader :gpiochip, :pwmchips, :i2cs, :spis

    def initialize(map_yaml=nil)
      # If a YAML map isn't given, only try to access gpiochip0.
      if map_yaml
        map = YAML.load_file(map_yaml, symbolize_names: true)
      else
        map = {gpiochip: 0}
      end

      # gpiochip validation
      @gpiochip = map[:gpiochip]
      raise ArgumentError, "invalid gpiochip: #{@gpiochip} given. Must be Integer" if @gpiochip.class != Integer

      # pwmchips validation
      @pwmchips = map[:pwmchips] || {}
      @pwmchips.each do |chip, channel_hash|
        raise ArgumentError, "invalid index for pwmchip: #{chip}. Should be Integer" if chip.class != Integer
        channel_hash.each do |chan, gpio|
          raise ArgumentError, "invalid Integer: #{chan} in keys (channels) of pwm_chip#{chip}" if chan.class != Integer
          raise ArgumentError, "invalid Integer: #{gpio} in values (GPIOs) of pwm_chip#{chip}" if gpio.class != Integer
        end
      end
      @hardware_pwms = {}

      # spis validation
      @spis = map[:spis] || {}
      @spis.each do |dev, gpios|
        raise ArgumentError, "invalid index for spi-dev: #{dev}. Should be Integer" if dev.class != Integer
        raise ArgumentError, "missing sck GPIO for spidev-#{dev}" unless @spis[dev][:sck]
        raise ArgumentError, "missing mosi GPIO for spidev-#{dev}" unless @spis[dev][:mosi]
        raise ArgumentError, "missing miso GPIO for spidev-#{dev}" unless @spis[dev][:miso]
        raise ArgumentError, "missing cs0 GPIO for spidev-#{dev}" unless @spis[dev][:cs0]
        gpios.each do |name, gpio|
          raise ArgumentError, "invalid Integer pin for #{name} in i2c#{dev}" if gpio.class != Integer
        end
      end

      # Config state storage for pins.
      @pin_configs = []

      # This thread will receive alerts from the LGPIO process and call #update.
      @alert_thread = nil
      @reporting_started = false

      # Immediately open the GPIO device
      @gpio_handle = LGPIO.chip_open(@gpiochip)
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
