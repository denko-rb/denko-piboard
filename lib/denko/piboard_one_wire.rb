module Denko
  class PiBoard
    attr_reader :one_wires

    def one_wire_claim(gpio)
      one_wire = LGPIO::OneWire.new(@gpio_handle, gpio)
      @one_wires ? @one_wires << one_wire : @one_wires = [one_wire]
      one_wire
    end

    def one_wire_lookup(gpio)
      if one_wires
        one_wires.each { |ow| return ow if (gpio == ow.gpio) }
      end
      one_wire_claim(gpio)
    end

    def one_wire_reset(gpio, check_presence=0)
      interface = one_wire_lookup(gpio)
      presence  = interface.reset ? 0 : 1
      self.update(gpio, [presence]) if check_presence != 0
    end

    def one_wire_search(gpio, branch_mask)
      interface    = one_wire_lookup(gpio)
      result_array = interface.search_pass(branch_mask)
      self.update(gpio, result_array)
    end

    def one_wire_write(gpio, parasite, *data)
      interface = one_wire_lookup(gpio)
      interface.write(data.flatten, parasite: parasite)
    end

    def one_wire_read(gpio, length)
      interface    = one_wire_lookup(gpio)
      result_array = interface.read(length)
      self.update(gpio, result_array)
    end
  end
end
