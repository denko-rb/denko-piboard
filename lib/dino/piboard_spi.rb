module Dino
  class PiBoard

    def spi_config(mode, bit_order)
      # Config is a 32-bit mask, where bits 0 and 1 are a 2-bit number equal to the SPI mode.
      # Default to SPI mode 0 when none given.
      config = mode || 0
      raise ArgumentError, "invalid SPI mode #{config}" unless (0..3).include? config

      # Default to :msbfirst when bit_order not given.
      bit_order ||= :msbfirst
      unless (bit_order == :msbfirst) || (bit_order == :lsbfirst)
        raise ArgumentError, "invalid bit order #{bitorder}"
      end

      # Bits 14 and 15 control MSBFIRST (0) or LSBFIRST (1) for MOSI and MISO respectively.
      # Use same order for both directions like Arduino does.
      config |= (0b11 << 14) if bit_order == :lsbfirst

      # Use SPI1 interface instead of SPI0.
      # Setting bit 8 means we're using SPI1.
      config |= (0b1 << 8)

      # Bits 5-7 set leaves all CE pins free, and allows any GPIO to be used for chip enable.
      # We toggle separately in #spi_transfer.
      config |= (0b111 << 5)

      return config
    end

    # CMD = 26
    def spi_transfer(select_pin, write: [], read: 0, frequency: nil, mode: nil, bit_order: nil)
      # Default to 1MHz SPI frequency.
      frequency ||= 1000000

      # Make SPI config mask.
      config = spi_config(mode, bit_order)

      # Open SPI handle.
      spi_open(frequency, config)
      
      # Chip enable low. select_pin == 255 means no chip enable (mostly for APA102 LEDs).
      digital_write(select_pin, 0) unless select_pin == 255

      # Do the SPI transfer.
      write_bytes = write.pack("C*")
      read_bytes = Pigpio::IF.spi_xfer(pi_handle, spi_handle, write_bytes)

      # Close SPI handle.
      spi_close

      # Chip enable high. select_pin == 255 means no chip enable (mostly for APA102 LEDs).
      digital_write(select_pin, 1) unless select_pin == 255

      # Handle spi_xfer errors.
      raise StandardError, "spi_xfer error, code #{read_bytes}" if read_bytes.class == Integer

      # Handle read bytes.
      if read > 0
        message = ""

        # Format like a microcontrolelr would. Limit to number of bytes requested.
        i = 0
        while i < read
          message = "#{message},#{read_bytes[i].ord}"
        end

        # Call update with the message as if coming from select_pin.
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

    attr_reader :spi_handle
    
    def spi_open(frequency, config)
      # Give SPI channel as 0 (SPI CE0), even though we are toggling chip enable separately.
      @spi_handle = Pigpio::IF.spi_open(pi_handle, 0, frequency, config)
      raise StandardError, "SPI error, code #{@spi_handle}" if @spi_handle < 0
    end

    def spi_close
      Pigpio::IF.spi_close(pi_handle, spi_handle)
      @spi_handle  = nil
    end

    def spi_listeners
      @spi_listeners ||= Array.new
    end
  end
end
