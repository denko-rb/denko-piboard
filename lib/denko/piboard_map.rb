module Denko
  class PiBoard
    MAP = {
      # Only use SPI1 interface.
      SS:   18,
      MISO: 19,
      MOSI: 20,
      SCK:  21,
      
      # Only use I2C1 interface.
      SDA: 2,
      SCL: 3,

      # Single UART
      TX: 14,
      RX: 15,
    }

    def map
      MAP
    end

    def convert_pin(pin)
      # Convert non numerical strings to symbols.
      pin = pin.to_sym if (pin.class == String) && !(pin.match (/\A\d+\.*\d*/))

      # Handle symbols.
      if (pin.class == Symbol)
        if map && map[pin]
          return map[pin]
        elsif map
          raise ArgumentError, "error in pin: #{pin.inspect}. Make sure that pin is defined for this board by calling Board#map"
        else
          raise ArgumentError, "error in pin: #{pin.inspect}. Given a Symbol, but board has no map. Try using GPIO integer instead"
        end
      end

      # Handle integers.
      return pin if pin.class == Integer

      # Try #to_i on anyting else. Will catch numerical strings.
      begin
        return pin.to_i
      rescue
        raise ArgumentError, "error in pin: #{pin.inspect}"
      end
    end
  end
end
