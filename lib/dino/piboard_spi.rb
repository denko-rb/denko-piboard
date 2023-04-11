module Dino
  class PiBoard

    def spi_config(options={})
      # Config is  a 32-bit mask, where bits 0 and 1 are a 2-bit number equal to the SPI mode.
      config = options[:mode] || 0b00
      raise ArgumentError, "invalid SPI mode #{config}" unless (0..3).include? config

      # Use SPI1 interface instead of SPI0.
      # Setting bit 8 means we're using SPI1.
      config |= (0b1 << 8)

      # Bits 5-7 set leaves all CE pins free, and allows any GPIO to be used for chip enable.
      # We'll toggle separately in #spi_transfer.
      config |= (0b111 << 5)

      # Bits 14 and 15 control MSBFIRST (0) or LSBFIRST (1) for MOSI and MISO respectively.
      config |= (0b11 << 14) if options[:bit_order] == :lsbfirst

      return config
    end

    # CMD = 26
    def spi_transfer(pin, options={})
      # Configure and open SPI handle.
      config = spi_config(options)
      baud = options[:frequency] || 1000000
      spi_open(baud, config)
      
      # Chip enable low.
      digital_write(pin, 0)

      # Do the SPI transfer.
      write_bytes = options[:write].pack("C*")
      read_bytes = Pigpio::IF.spi_xfer(pi_handle, spi_handle, write_bytes)

      # Close SPI handle.
      spi_close

      # Chip enable high.
      digital_write(pin, 1)

      # Handle spi_xfer errors.
      raise StandardError, "spi_xfer error, code #{read_bytes}" if read_bytes.class == Integer

      # Deal with any read bytes.
      if options[:read]
        # Truncate to the number of bytes requested.
        read_bytes = read_bytes[0..(options[:read]-1)]

        # Format like dino expects from a microcontroller.
        message = read_bytes.split("").map { |byte| byte.ord.to_s }.join(",")

        # Call update with the message as if coming from the chip select pin.
        self.update(pin, message)
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
    
    def spi_open(baud, config)
      # Give SPI channel as 0 (SPI CE0), even though we are toggling chip enable separately.
      @spi_handle = Pigpio::IF.spi_open(pi_handle, 0, baud, config)
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
