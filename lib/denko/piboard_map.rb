require 'yaml'

module Denko
  class PiBoard
    DEFAULT_MAP_FILE = ".denko_piboard_map.yml"

    attr_reader :map, :alert_lut

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

    # Keep track of pins bound by non-GPIO peripherals.
    def bound_pins
      @bound_pins ||= []
    end

    def convert_pin(pin)
      pin.to_i if pin
    end
  end
end
