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
    def spi_transfer(index, select, write:[], read:0, frequency: 1_000_000, mode: 0, bit_order: nil)
      # Default frequency. Flags just has mode.
      frequency ||= 1_000_000
      flags       = spi_flags(mode)
      handle      = spi_open(index, frequency, flags)

      # Handle select_pin unless it's same as CS0 for this interface.
      digital_write(select, 0) if select && (select != map[:spis][index][:cs0])
      bytes = LGPIO.spi_xfer(handle, write)
      spi_close(handle)
      digital_write(select, 1) if select && (select != map[:spis][index][:cs0])

      spi_c_error("xfer", bytes, index) if bytes.class == Integer

      # Update component attached to select pin with read bytes.
      self.update(select, bytes) if (read > 0 && select)
    end

    # CMD = 27
    def spi_listen(*arg, **kwargs)
    end

    # CMD = 28
    def spi_stop(pin)
    end

    def spi_listeners
      @spi_listeners ||= Array.new
    end

    private

    def spi_mutex(index)
      spi_mutexes[index] ||= Mutex.new
    end

    def spi_mutexes
      @spi_mutexes ||= []
    end

    def spi_open(index, frequency, flags=0x00)
      # Always use 0 (SPI CS0) for channel. We are toggling chip enable separately.
      handle = LGPIO.spi_open(index, 0, frequency, flags)
      spi_c_error("open", handle, index) if handle < 0
      handle
    end

    def spi_close(handle)
      result = LGPIO.spi_close(handle)
      if result < 0
        raise StandardError, "lgpio C SPI close error: #{result} for handle #{handle}"
      end
    end

    def spi_c_error(name, error, index)
      raise StandardError, "lgpio C SPI #{name} error: #{error} for /dev/spidev#{index}"
    end
  end
end
