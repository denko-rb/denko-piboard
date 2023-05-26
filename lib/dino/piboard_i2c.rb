module Dino
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
        # Try each address in 8..19 (0x08 to 0x77).
        (0x08..0x77).each do |address|
          i2c_open(1, address)
          byte = Pigpio::IF.i2c_read_byte(pi_handle, i2c_handle)
          # Add to the string colon separated if byte was valid.
          found_string << "#{address}:" if byte >= 0
          i2c_close
        end

        # Remove trailing colon.
        found_string.chop! unless found_string.empty?

        # Update the bus as if message came from microcontroller.
        self.update(2, found_string)
      end
    end

    # CMD = 34
    def i2c_write(address, bytes, frequency=100000, repeated_start=false)
      i2c_mutex.synchronize do
        raise ArgumentError, "can't write more than #{i2c_limit} bytes to I2C" if bytes.length > i2c_limit

        # Pack length as a 16-bit uint, then unpack it into 2 litle endian bytes.
        length = [bytes.length].pack("S").unpack("C*")

        # Prepend length to the bytes.
        bytes = length + bytes

        # Prepend write command and escape character (necessary for double byte write length).
        bytes = [0x01, 0x07] + bytes
        
        # Enable and (re)disable repeated start as needed.
        bytes = [0x02] + bytes + [0x03] if repeated_start

        # Null terminate the command sequence.
        bytes = bytes + [0x00]

        # Send the command to the I2C1 interface, packed as uint8 string.
        i2c_open(1, address)
        Pigpio::IF.i2c_zip(pi_handle, i2c_handle, bytes.pack("C*"), 0)
        i2c_close
      end
    end

    # CMD = 35
    def i2c_read(address, register, read_length, frequency=100000, repeated_start=false)
      i2c_mutex.synchronize do
        raise ArgumentError, "can't read more than #{i2c_limit} bytes to I2C" if read_length > i2c_limit
        
        # Start with number of bytes to read (16-bit number) represented as 2 little endian bytes.
        buffer = [read_length].pack("S").unpack("C*")

        # Prepend read command and escape character (necessary for double byte write length).
        buffer = [0x01, 0x06] + buffer

        # If a start register was given, write it first.
        if register
          register = [register].flatten
          raise ArgumentError, "can't pre-write a register address > 4 bytes" if register.length > 4
          buffer = [0x07, register.length] + register + buffer
        end

        # Enable and (re)disable repeated start as needed.
        buffer = [0x02] + buffer + [0x03] if repeated_start

        # Null terminate the command sequence.
        buffer = buffer + [0x00]

        # Send the command to the I2C1 interface, packed as uint8 string.
        i2c_open(1, address)
        read_bytes = Pigpio::IF.i2c_zip(pi_handle, i2c_handle, buffer.pack("C*"), read_length)
        i2c_close

        # Pigpio returned an error. Dino expects blank message after address.
        if read_bytes.class == Integer
          message = "#{address}-"
        else
          # Format the bytes like dino expects from a microcontroller.
          message = read_bytes.split("").map { |byte| byte.ord.to_s }.join(",")
          message = "#{address}-#{message}"
        end
        
        # Call update with the message, as if it came from pin 2 (I2C1 SDA pin).
        self.update(2, message)
      end
    end

    private

    attr_reader :i2c_handle

    def i2c_open(bus_index, address)
      @i2c_handle = Pigpio::IF.i2c_open(pi_handle, bus_index, address, 0)
      raise StandardError, "I2C error, code #{@i2c_handle}" if @i2c_handle < 0
    end

    def i2c_close
      Pigpio::IF.i2c_close(pi_handle, i2c_handle)
      @i2c_handle = nil
    end
  end
end
