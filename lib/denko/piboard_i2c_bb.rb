module Denko
  class PiBoard
    def i2c_bbs
      @i2c_bbs ||= []
    end

    def i2c_bb_interface(scl, sda)
      # Convert the pins into a config array to check.
      ch, cl = gpio_tuple(scl)
      dh, dl = gpio_tuple(sda)
      config = [ch, cl, dh, dl]

      # Check if any already exists with that array and return it.
      i2c_bbs.each { |bb| return bb if (config == bb.config) }

      # If not, create one.
      hash =  { scl:  { handle: ch, line: cl },
                sda:  { handle: dh, line: dl } }

      i2c_bb = LGPIO::I2CBitBang.new(hash)
      i2c_bbs << i2c_bb
      i2c_bb
    end

    def i2c_bb_search(scl, sda)
      interface    = i2c_bb_interface(scl, sda)
      devices      = interface.search
      found_string = ""
      found_string = devices.join(":") if devices
      self.update(sda, found_string)
    end

    def i2c_bb_write(scl, sda, address, bytes, repeated_start=false)
      interface = i2c_bb_interface(scl, sda)
      interface.write(address, bytes)
    end

    def i2c_bb_read(scl, sda, address, register, read_length, repeated_start=false)
      interface = i2c_bb_interface(scl, sda)
      interface.write(address, register) if register
      bytes = interface.read(address, read_length)

      # Prepend the address (0th element) to the data, and update the SDA pin.
      bytes.unshift(address)
      self.update(sda, bytes)
    end
  end
end
