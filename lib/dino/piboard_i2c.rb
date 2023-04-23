module Dino
  class PiBoard
    # Maximum amount of bytes that can be read or written in a single I2C operation.
    def i2c_limit
      65535
    end

    # CMD = 33
    def i2c_search
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

    # CMD = 34
    def i2c_write(address, bytes=[], options={})
      raise ArgumentError, "can't write more than 65535 bytes to I2C" if bytes.length > 65535

      # Create a command buffer, starting with the raw I2C bytes.
      buffer = bytes.dup

      # Pack length as a 16-bit uint, then unpack it into 2 litle endian bytes.
      length = [bytes.length].pack("S").unpack("C*")

      # Prepend length bytes to the buffer in the right order.
      buffer.unshift length.pop
      buffer.unshift length.pop

      # Prepend write command and escape character (necessary for double byte write length).
      buffer.unshift 0x07
      buffer.unshift 0x01

      # Enable and (re)disable repeated start as needed.
      if options[:repeated_start]
        buffer.unshift 0x02
        buffer.push    0x03
      end

      # Null terminate the command sequence.
      buffer.push 0x00

      # Pack it into a string as uint8.
      buffer = buffer.pack("C*")

      # Write it to the I2C1 interface.
      i2c_open(1, address)
      Pigpio::IF.i2c_zip(pi_handle, i2c_handle, buffer, 0)
      i2c_close
    end

    # CMD = 35
    def i2c_read(address, register, read_length, options={})
      raise ArgumentError, "can't read more than 65535 bytes to I2C" if read_length > 65535

      # Start with an empty buffer for the command sequence.
      buffer = []

      # Pack length as a 16-bit uint, then unpack it into 2 litle endian bytes.
      length = [read_length].pack("S").unpack("C*")

      # Prepend length bytes to the buffer in the right order.
      buffer.unshift length.pop
      buffer.unshift length.pop

      # Prepend read command and escape character (necessary for double byte write length).
      buffer.unshift 0x06
      buffer.unshift 0x01

      # If a start register was given, write it first.
      # TODO: Only supports 1 byte register addresses.
      if register
        buffer.unshift register
        buffer.unshift 1
        buffer.unshift 0x07
      end

      # Enable and (re)disable repeated start as needed.
      if options[:repeated_start]
        buffer.unshift 0x02
        buffer.push    0x03
      end

      # Null terminate the command sequence.
      buffer.push 0x00

      # Pack it into a string as uint8.
      buffer = buffer.pack("C*")

      # Read from the I2C1 interface.
      i2c_open(1, address)
      read_bytes = Pigpio::IF.i2c_zip(pi_handle, i2c_handle, buffer, read_length)
      i2c_close

      # Format the bytes like dino expects from a microcontroller.
      message = read_bytes.split("").map { |byte| byte.ord.to_s }.join(",")
      message = "#{address}-#{message}"

      # Call update with the message, as if it came from pin 2 (I2C1 SDA pin).
      self.update(2, message)
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
