module Denko
  class PiBoard
    # Maximum amount of bytes that can be read or written in a single I2C operation.
    def i2c_limit
      65535
    end

    def i2c_mutex
      @i2c_mutex ||= Mutex.new
    end

    # CMD = 33
    def i2c_search
      i2c_mutex.synchronize do
        found_string = ""

        # Address ranges 0..7 and 120..127 are reserved.
        # Try each address in 8..119 (0x08 to 0x77).
        (0x08..0x77).each do |address|
          i2c_open(@i2c_devs.first[:index], address)
          bytes = LGPIO.i2c_read_device(@i2c_handle, 1)
          found_string << "#{address}:" if bytes[0] > 0
          i2c_close
        end

        # Remove trailing colon.
        found_string.chop! unless found_string.empty?

        # Update the bus as if message came from microcontroller.
        self.update(@i2c_devs.first[:sda], found_string)
      end
    end

    # CMD = 34
    def i2c_write(address, bytes, frequency=nil, repeated_start=false)
      i2c_mutex.synchronize do
        raise ArgumentError, "can't write more than #{i2c_limit} bytes to I2C" if bytes.length > i2c_limit

        i2c_open(@i2c_devs.first[:index], address)
        LGPIO.i2c_write_device(@i2c_handle, bytes)
        i2c_close
      end
    end

    # CMD = 35
    def i2c_read(address, register, read_length, frequency=nil, repeated_start=false)
      i2c_mutex.synchronize do
        raise ArgumentError, "can't read more than #{i2c_limit} bytes to I2C" if read_length > i2c_limit

        i2c_open(@i2c_devs.first[:index], address)
        LGPIO.i2c_write_device(@i2c_handle, register) if register
        bytes = LGPIO.i2c_read_device(@i2c_handle, read_length)
        i2c_close

        # Format the bytes like denko expects from a microcontroller.
        message = "#{address}-#{bytes.join(",")}"

        # Update the bus as if message came from microcontroller.
        self.update(@i2c_devs.first[:sda], message)
      end
    end

    private

    def i2c_open(index, address, flags=0x00)
      @i2c_handle = LGPIO.i2c_open(index, address, flags)
      raise StandardError, "Could not open I2C device with index #{@index}" if @i2c_handle < 0
    end

    def i2c_close
      LGPIO.i2c_close(@i2c_handle)
      @i2c_handle = nil
    end
  end
end
