module Denko
  class PiBoard
    def spi_flags(mode)
      mode ||= 0
      raise ArgumentError, "invalid SPI mode #{mode}" unless (0..3).include? mode

      # Flags is a 32-bit mask. Bits [1..0] are the SPI mode. Default to 0.
      config = mode

      return config
    end

    # CMD = 26
    def spi_transfer(select_pin, write:[], read:0, frequency: 1_000_000, mode: 0, bit_order: nil)
      # Default to 1Mhz frequency.
      frequency ||= 1_000_000

      # Make SPI flags mask.
      flags = spi_flags(mode)

      # Open SPI handle.
      spi_open(@spis.keys.first, 0, frequency, flags)

      # Pull select_pin low unless it's 255 (no select pin) or CS0 (interface will do it).
      unless [@spis.values.first[:cs0], 255].include? select_pin
        digital_write(select_pin, 0) unless select_pin == 255
      end

      # Do the SPI transfer.
      read_bytes = LGPIO.spi_xfer(@spi_handle, write)

      # Close SPI handle.
      spi_close

      # Put select_pin back high if needed.
      unless [@spis.values.first[:cs0], 255].include? select_pin
        digital_write(select_pin, 1) unless select_pin == 255
      end

      # Handle spi_xfer errors.
      raise StandardError, "spi_xfer error, code #{read_bytes}" if read_bytes.class == Integer

       # If reading bytes, call #update as if coming from select_pin.
      if read > 0
        message = read_bytes.take(read).join(",")
        self.update(select_pin, message)
      end
    end

    # CMD = 27
    def spi_listen
    end

    # CMD = 28
    def spi_stop
    end

    private

    def spi_open(index, channel, frequency, flags=0x00)
      # Give SPI channel as 0 (SPI CE0), even though we are toggling chip enable separately.
      @spi_handle = LGPIO.spi_open(index, channel, frequency, flags)
      raise StandardError, "SPI error, code #{@spi_handle}" if @spi_handle < 0
    end

    def spi_close
      LGPIO.spi_close(@spi_handle)
      @spi_handle  = nil
    end

    def spi_listeners
      @spi_listeners ||= Array.new
    end
  end
end
