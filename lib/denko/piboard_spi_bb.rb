module Denko
  class PiBoard
    attr_reader :spi_bbs

    def spi_bb_claim(config)
      spi_bb = LGPIO::SPIBitBang.new(config)
      @spi_bbs ? @spi_bbs << spi_bb : @spi_bbs = [spi_bb]
      spi_bb
    end

    def spi_bb_lookup(config)
      if spi_bbs
        spi_bbs.each { |bb| return bb if (config == bb.config) }
      end
      spi_bb_claim(config)
    end

    def spi_bb_transfer(select_pin, clock: nil, input: nil, output: nil, write: [], read: 0, frequency: nil, mode: nil, bit_order: nil)
      config = { handle: @gpio_handle, clock: clock, input: input, output: output }
      interface = spi_bb_lookup(config)

      read_bytes = interface.transfer(write: write, read: read)
      # Update with comma delimited byte string as if coming from microcontroller.
      self.update(select_pin, read_bytes.join(",")) if read_bytes
    end
  end
end
