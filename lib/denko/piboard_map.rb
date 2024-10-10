require 'yaml'

module Denko
  class PiBoard
    DEFAULT_MAP_FILE = ".denko_piboard_map.yml"

    attr_reader :map, :alert_lut, :gpiochip_lookup_optimized

    def parse_map(map_yaml)
      @map = YAML.load_file(map_yaml, symbolize_names: true)

      # Validate GPIO chip and line numbers for pins. Also build a lookup table for alerts.
      @alert_lut = []
      map[:pins].each_pair do |k, h|
        raise StandardError, "invalid pin number: #{k} in YAML map :pins. Should be Integer"  unless k.class == Integer
        raise StandardError, "invalid GPIO chip for GPIO #{k[:chip]}. Should be Integer"      unless h[:chip].class == Integer
        raise StandardError, "invalid GPIO chip for GPIO #{k[:line]}. Should be Integer"      unless h[:line].class == Integer
        @alert_lut[h[:chip]] ||= []
        @alert_lut[h[:chip]][h[:line]] = k
      end

      # Validate PWMs
      map[:pwms].each_pair do |k, h|
        raise StandardError, "invalid pin number: #{k} in YAML map :pwms. Should be Integer"    unless k.class == Integer
        raise StandardError, "invalid pwmchip: #{h[:pwmchip]}} for pin #{k}. Should be Integer" unless h[:pwmchip].class == Integer
        raise StandardError, "invalid channel: #{h[:channel]}} for pin #{k}. Should be Integer" unless h[:channel].class == Integer

        dev_path = "/sys/class/pwm/pwmchip#{h[:pwmchip]}/pwm#{h[:channel]}"
        raise StandardError, "board map error. Pin #{k} appears to be bound to both #{dev_path} and #{bound_pins[k]}" if bound_pins[k]
        bound_pins[k] = dev_path
      end

      # Validate I2Cs
      map[:i2cs].each_pair do |k, h|
        raise StandardError, "invalid pin number: #{k} in YAML map :i2cs. Should be Integer"  unless k.class == Integer
        raise StandardError, "invalid scl: #{h[:scl]}} for pin #{k}. Should be Integer"       unless h[:scl].class == Integer
        raise StandardError, "invalid sda: #{h[:sda]}} for pin #{k}. Should be Integer"       unless h[:sda].class == Integer

        dev_path = "/dev/i2c-#{k}"
        raise StandardError, "board map error. Pin #{k} appears to be bound to both #{dev_path} and #{bound_pins[k]}" if bound_pins[k]
        bound_pins[k] = dev_path
      end

      # Validate SPIs
      map[:spis].each_pair do |k, h|
        raise StandardError, "invalid pin number: #{k} in YAML map :spis. Should be Integer"  unless k.class == Integer
        raise StandardError, "invalid clk: #{h[:clk]}} for pin #{k}. Should be Integer"       unless h[:clk].class == Integer
        raise StandardError, "invalid mosi: #{h[:mosi]}} for pin #{k}. Should be Integer"     unless h[:mosi].class == Integer
        raise StandardError, "invalid miso: #{h[:miso]}} for pin #{k}. Should be Integer"     unless h[:miso].class == Integer
        raise StandardError, "invalid cs0: #{h[:cs0]}} for pin #{k}. Should be Integer"       unless h[:cs0].class == Integer

        dev_path = "dev/spidev#{k}.0"
        raise StandardError, "board map error. Pin #{k} appears to be bound to both #{dev_path} and #{bound_pins[k]}" if bound_pins[k]
        bound_pins[k] = dev_path
      end

      load_gpiochip_lookup_optimizations
    end

    #
    # Monkey patch to eliminate lookups, and improve performance,
    # when all GPIO lines are on a single gpiochip, and the readable
    # GPIO numbers exactly match the GPIO line numbers.
    #
    def load_gpiochip_lookup_optimizations
      @gpiochip_lookup_optimized = false

      # Makes performance slightly worse on YJIT?
      return if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?

      # All pins must be defined on the same gpiochip.
      unique_gpiochips = map[:pins].each_value.map { |pin_def| pin_def[:chip] }.uniq
      return if unique_gpiochips.length != 1

      # For each pin, the key integer must be equal to the line integer.
      map[:pins].each_pair do |gpio_num, pin_def|
        return unless (gpio_num == pin_def[:line])
      end

      # Open the handle so it can be given as a literal in the optimized methods.
      gpiochip_single_handle = gpio_handle(unique_gpiochips.first)

      code = File.read(File.dirname(__FILE__) + "/piboard_core_optimize_lookup.rb")
      code = code.gsub("__GPIOCHIP_SINGLE_HANDLE__", gpiochip_single_handle.to_s)

      singleton_class.class_eval(code)
      @gpiochip_lookup_optimized = true
    end

    # Make a new tuple, given a human-readable pin number, using values from the map.
    def gpio_tuple(index)
      return gpio_tuples[index] if gpio_tuples[index]

      raise ArgumentError, "pin #{index} does not exist or not included in map" unless map[:pins][index]
      raise ArgumentError, "pin #{index} cannot be used as GPIO. Bound to #{bound_pins[index]}" if bound_pins[index]

      handle = gpio_handle(map[:pins][index][:chip])
      line = map[:pins][index][:line]

      gpio_tuples[index] = [handle, line]
    end

    # Cache tuples of [handle, line_number], keyed to human-readable pin numbers.
    def gpio_tuples
      @gpio_tuples ||= []
    end

    # Store multiple LGPIO handles, since one board might have multiple chips.
    def gpio_handle(index)
      gpio_handles[index] ||= LGPIO.chip_open(index)
    end

    def gpio_handles
      @gpio_handles ||= []
    end

    # Keep track of pins bound by non-GPIO peripherals.
    def bound_pins
      @bound_pins ||= []
    end

    def convert_pin(pin)
      pin.to_i if pin
    end
  end
end
