module Denko
  class PiBoard
    # Maximum amount of bytes that can be read or written in a single I2C operation.
    def i2c_limit
      65535
    end

    # CMD = 33
    def i2c_search(index)
      i2c_mutex(index).synchronize do
        found_string = ""

        # Address ranges 0..7 and 120..127 are reserved.
        # Try each address in 8..119 (0x08 to 0x77).
        (0x08..0x77).each do |address|
          handle = i2c_open(index, address)
          bytes = LGPIO.i2c_read_device(handle, 1)
          found_string << "#{address}:" if bytes[0] > 0
          i2c_close(handle)
        end

        update_i2c(index, found_string)
      end
    end

    # CMD = 34
    def i2c_write(index, address, bytes, frequency=nil, repeated_start=false)
      i2c_mutex(index).synchronize do
        raise ArgumentError, "exceeded #{i2c_limit} bytes for #i2c_write" if bytes.length > i2c_limit

        handle = i2c_open(index, address)
        result = LGPIO.i2c_write_device(handle, bytes)
        i2c_close(handle)
        i2c_c_error("write", result, index, address) if result < 0
      end
    end

    # CMD = 35
    def i2c_read(index, address, register, read_length, frequency=nil, repeated_start=false)
      i2c_mutex(index).synchronize do
        raise ArgumentError, "can't read more than #{i2c_limit} bytes to I2C" if read_length > i2c_limit

        handle = i2c_open(index, address)
        if register
          result = LGPIO.i2c_write_device(handle, register)
          i2c_c_error("read (register write)", result, index, address) if result < 0
        end

        bytes = LGPIO.i2c_read_device(handle, read_length)
        i2c_close(handle)
        i2c_c_error("read", bytes, index, address) if bytes.class == Integer

        # Prepend the address (0th element) to the data, and update the bus.
        bytes.unshift(address)
        update_i2c(index, bytes)
      end
    end

    private

    def i2c_mutex(index)
      i2c_mutexes[index] ||= Mutex.new
    end

    def i2c_mutexes
      @i2c_mutexes ||= []
    end

    def i2c_open(index, address, flags=0x00)
      handle = LGPIO.i2c_open(index, address, flags)
      i2c_c_error("open", handle, index, address) if handle < 0
      handle
    end

    def i2c_close(handle)
      result = LGPIO.i2c_close(handle)
      if result < 0
        raise StandardError, "lgpio C I2C close error: #{result} for /dev/i2c-#{index}"
      end
    end

    def i2c_c_error(name, error, index, address)
      raise StandardError, "lgpio C I2C #{name} error: #{error} for /dev/i2c-#{index} with address 0x#{address.to_s(16)}"
    end

    def update_i2c(index, data)
      dev = hw_i2c_devs[index]
      dev.update(data) if dev
    end
  end
end
