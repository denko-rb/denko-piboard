module Denko
  class PiBoard
    # Maximum amount of bytes that can be read or written in a single I2C operation.
    def i2c_limit
      65535
    end

    def i2c_mutex
      @i2c_mutex ||= Mutex.new
    end

    def i2c_c_error(name, error, index, address)
      raise StandardError, "lgpio C I2C #{name} error: #{error} for /dev/i2c-#{index} with address 0x#{address.to_s(16)}"
    end

    def update_i2c(i2c_index, data)
      dev = hw_i2c_devs[i2c_index]
      dev.update(data) if dev
    end

    # CMD = 33
    def i2c_search(i2c_index)
      i2c_mutex.synchronize do
        found_string = ""

        # Address ranges 0..7 and 120..127 are reserved.
        # Try each address in 8..119 (0x08 to 0x77).
        (0x08..0x77).each do |address|
          i2c_open(i2c_index, address)
          bytes = LGPIO.i2c_read_device(i2c_handle, 1)
          found_string << "#{address}:" if bytes[0] > 0
          i2c_close
        end
        # Remove trailing colon.
        found_string.chop! unless found_string.empty?

        update_i2c(i2c_index, found_string)
      end
    end

    # CMD = 34
    def i2c_write(i2c_index, address, bytes, frequency=nil, repeated_start=false)
      i2c_mutex.synchronize do
        raise ArgumentError, "can't write more than #{i2c_limit} bytes to I2C" if bytes.length > i2c_limit

        i2c_open(i2c_index, address)
        result = LGPIO.i2c_write_device(i2c_handle, bytes)
        i2c_c_error("write", result, i2c_index, address) if result < 0

        i2c_close
      end
    end

    # CMD = 35
    def i2c_read(i2c_index, address, register, read_length, frequency=nil, repeated_start=false)
      i2c_mutex.synchronize do
        raise ArgumentError, "can't read more than #{i2c_limit} bytes to I2C" if read_length > i2c_limit

        i2c_open(i2c_index, address)
        if register
          result = LGPIO.i2c_write_device(i2c_handle, register)
          i2c_c_error("register write (in read)", result, i2c_index, address) if result < 0
        end

        bytes = LGPIO.i2c_read_device(i2c_handle, read_length)
        i2c_close

        # Some error. -42 means read failed, so just return nil.
        if bytes.class == Integer
          if bytes == -42
            message = nil
          else
            i2c_c_error("read", bytes, i2c_index, address)
          end
        else
          # Format bytes like denko expects from a microcontroller.
          message = "#{address}-#{bytes.join(",")}"
        end

        # Update the bus as if message came from microcontroller.
        update_i2c(i2c_index, message)
      end
    end

    private

    def i2c_open(index, address, flags=0x00)
      @i2c_handle = LGPIO.i2c_open(index, address, flags)
      i2c_c_error("open", @i2c_handle, index, address) if @i2c_handle < 0
    end

    def i2c_close
      LGPIO.i2c_close(@i2c_handle)
      @i2c_handle = nil
    end

    attr_reader :i2c_handle
  end
end
