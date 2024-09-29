module Denko
  class PiBoard
    attr_reader :spi_bbs

    def spi_bbs
      @spi_bbs ||= []
    end

    def spi_bb_interface(clock, input, output)
      # Convert the pins into a config array to check.
      ch, cl = gpio_tuple(clock)
      ih, il = input  ? gpio_tuple(input)  : [nil, nil]
      oh, ol = output ? gpio_tuple(output) : [nil, nil]
      config = [ch, cl, ih, il, oh, ol]

      # Check if any already exists with that array and return it.
      spi_bbs.each { |bb| return bb if (config == bb.config) }

      # If not, create one.
      hash =  { clock:  { handle: ch, line: cl },
                input:  { handle: ih, line: il },
                output: { handle: oh, line: ol } }

      spi_bb = LGPIO::SPIBitBang.new(hash)
      spi_bbs << spi_bb
      spi_bb
    end

    def spi_bb_transfer(select_pin, clock:, input: nil, output: nil, write: [], read: 0, frequency: nil, mode: nil, bit_order: nil)
      interface = spi_bb_interface(clock, input, output)

      read_bytes = interface.transfer(write: write, read: read)
      # Update with comma delimited byte string as if coming from microcontroller.
      self.update(select_pin, read_bytes.join(",")) if read_bytes
    end
  end
end
