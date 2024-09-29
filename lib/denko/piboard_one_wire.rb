module Denko
  class PiBoard
    def one_wires
      @one_wires ||= []
    end

    def one_wire_interface(pin)
      handle, gpio  = gpio_tuple(pin)

      # Check if any already exists with that array and return it.
      one_wires.each { |bb| return bb if (handle == bb.handle && gpio == bb.gpio) }

      # If not, create one.
      one_wire = LGPIO::OneWire.new(handle, gpio)
      one_wires << one_wire
      one_wire
    end

    def one_wire_reset(gpio, check_presence=0)
      interface = one_wire_interface(gpio)
      presence  = interface.reset ? 0 : 1
      self.update(gpio, [presence]) if check_presence != 0
    end

    def one_wire_search(gpio, branch_mask)
      interface    = one_wire_interface(gpio)
      result_array = interface.search_pass(branch_mask)
      self.update(gpio, result_array)
    end

    def one_wire_write(gpio, parasite, *data)
      interface = one_wire_interface(gpio)
      interface.write(data.flatten, parasite: parasite)
    end

    def one_wire_read(gpio, length)
      interface    = one_wire_interface(gpio)
      result_array = interface.read(length)
      self.update(gpio, result_array)
    end
  end
end
