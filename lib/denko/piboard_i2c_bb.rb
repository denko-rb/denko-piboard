module Denko
  class PiBoard
    # CMD = 30
    def i2c_bb_search(scl, sda)
      devices = LGPIO.i2c_bb_search(@gpio_handle, scl, sda)
      found_string = ""
      found_string = devices.join(":") if devices
      self.update(sda, found_string)
    end

    # CMD = 31
    def i2c_bb_write(scl, sda, address, bytes, repeated_start=false)
      LGPIO.i2c_bb_write(@gpio_handle, scl, sda, address, bytes)
    end

    # CMD = 32
    def i2c_bb_read(scl, sda, address, register, read_length, repeated_start=false)
      LGPIO.i2c_bb_write(@gpio_handle, scl, sda, address, register) if register
      bytes = LGPIO.i2c_bb_read(@gpio_handle, scl, sda, address, read_length)

      # Format the bytes like denko expects from a microcontroller.
      message = "#{address}-#{bytes.join(",")}"

      # Update the bus as if message came from microcontroller.
      self.update(sda, message)
    end
  end
end
