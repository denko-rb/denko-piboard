require 'denko'
require 'lgpio'

module Denko
  class PiBoard
    include Behaviors::Subcomponents

    LOW      = 0
    HIGH     = 1
    PWM_HIGH = 100
    def low;      LOW;      end
    def high;     HIGH;     end
    def pwm_high; PWM_HIGH; end
    def analog_write_resolution; 8; end

    def initialize(map_yaml_file=nil)
      map_yaml_file ||= Dir.home + "/" + DEFAULT_MAP_FILE
      unless File.exist?(map_yaml_file)
        raise StandardError, "board map file not given to PiBoard#new, and does not exist at #{map_yaml_file}"
      end

      parse_map(map_yaml_file)
    end

    def finish_write
      gpio_handles.each { |h| LGPIO.chip_close(h) if h }
    end

    def update(pin, message)
      if single_pin_components[pin]
        single_pin_components[pin].update(message)
      end
    end
  end
end
