module Denko
  class PiBoard
    attr_reader :i2c_bbs

    def i2c_bb_claim(scl, sda)
      i2c_bb = LGPIO::I2CBitBang.new(@gpio_handle, scl, sda)
      @i2c_bbs ? @i2c_bbs << i2c_bb : @i2c_bbs = [i2c_bb]
      i2c_bb
    end

    def i2c_bb_lookup(scl, sda)
      if i2c_bbs
        i2c_bbs.each { |bb| return bb if (scl == bb.scl) && (sda == bb.sda) }
      end
      i2c_bb_claim(scl, sda)
    end

    def i2c_bb_search(scl, sda)
      interface    = i2c_bb_lookup(scl, sda)
      devices      = interface.search
      found_string = ""
      found_string = devices.join(":") if devices
      self.update(sda, found_string)
    end

    def i2c_bb_write(scl, sda, address, bytes, repeated_start=false)
      interface = i2c_bb_lookup(scl, sda)
      interface.write(address, bytes)
    end

    def i2c_bb_read(scl, sda, address, register, read_length, repeated_start=false)
      interface = i2c_bb_lookup(scl, sda)
      interface.write(address, register) if register
      bytes = interface.read(address, read_length)

      # Format the bytes like denko expects from a microcontroller.
      message = "#{address}-#{bytes.join(",")}"

      # Update the bus as if message came from microcontroller.
      self.update(sda, message)
    end
  end
end
