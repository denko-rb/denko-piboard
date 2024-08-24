module Denko
  class PiBoard
    def one_wire_reset(pin, value=0)
      result = LGPIO.one_wire_reset(@gpio_handle, pin)
      self.update(pin, [result]) if value > 0
    end

    def one_wire_search(pin, branch_mask)
      result_array = LGPIO.one_wire_search(@gpio_handle, pin, branch_mask)
      self.update(pin, result_array)
    end

    def one_wire_write(pin, parasite_power, *data)
      parasite_int = parasite_power ? 1 : 0
      LGPIO.one_wire_write(@gpio_handle, pin, parasite_int, data.flatten)
    end

    def one_wire_read(pin, num_bytes)
      result_array = LGPIO.one_wire_read(@gpio_handle, pin, num_bytes)
      self.update(pin, result_array)
    end
  end
end
