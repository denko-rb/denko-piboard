require 'dino'
require 'pigpio'
include Pigpio::Constant

module Dino
  class PiBoard
    attr_reader :components, :high, :low, :pwm_high

    def initialize
      @components = []
      @pin_callbacks = []
      @pin_pwms = []
      
      @low  = 0
      @high = 1
      @pwm_high = 255

      # Use the interface class directly.
      @pi_handle = Pigpio::IF.pigpio_start
      exit(-1) if @pi_handle < 0
    end

    def finish_write
      Pigpio::IF.pigpio_stop(@pi_handle)
    end

    def update(pin, message, time=nil)
      update_component(pin, message)
    end

    def update_component(pin, message)
      @components.each do |part|
        part.update(message) if part.pin.to_i == pin
      end
    end

    def add_component(component)
      @components << component
    end

    def remove_component(component)
      component.stop if component.methods.include? :stop
      @components.delete(component)
    end

    # CMD = 0
    def set_pin_mode(pin, mode=:input)
      pwm_clear(pin)
      gpio = get_gpio(pin)

      # Output
      if mode.to_s.match /output/
        gpio.mode = PI_OUTPUT

      # Input
      else
        gpio.mode = PI_INPUT
        # Only trigger state change if level has been stable for 90us.
        gpio.glitch_filter(90)

        # Pull down/up/none
        if mode.to_s.match /pulldown/
          gpio.pud = PI_PUD_DOWN
        elsif mode.to_s.match /pullup/
          gpio.pud = PI_PUD_UP
        else
          gpio.pud = PI_PUD_OFF
        end
      end
    end

    # CMD = 1
    def digital_write(pin, value)
      pwm_clear(pin)
      get_gpio(pin).write(value)
    end
    
    # CMD = 2
    def digital_read(pin)
      if @pin_pwms[pin]
        @pin_pwms[pin].dutycycle
      else
        get_gpio(pin).read
      end
    end

    # CMD = 3
    def pwm_write(pin, value)
      # Disable servo if necessary.
      pwm_clear(pin) if @pin_pwms[pin] == :servo

      unless @pin_pwms[pin]
        @pin_pwms[pin] = get_gpio(pin).pwm
        @pin_pwms[pin].frequency = 1000
      end
      @pin_pwms[pin].dutycycle = value
    end

    # CMD = 6
    def set_listener(pin, state=:off, options={})
      # Listener on
      if state == :on && !@pin_callbacks[pin]
        callback = get_gpio(pin).callback(EITHER_EDGE) do |tick, level, pin_cb|
          update(pin_cb, level, tick)
        end
        @pin_callbacks[pin] = callback

      # Listener off
      else
        @pin_callbacks[pin].cancel if @pin_callbacks[pin]
        @pin_callbacks[pin] = nil
      end
    end

    def digital_listen(pin, divider=4)
      set_listener(pin, :on, {})
    end

    def stop_listener(pin)
      set_listener(pin, :off)
    end

    # CMD = 10
    def servo_toggle(pin, value=:off, options={})
      if value == :off
        pwm_clear(pin)
        digital_write(pin, 0)
      else
        @pin_pwms[pin] = :servo
      end
    end
    
    # CMD = 11
    def servo_write(pin, value=0)
      Pigpio::IF.set_servo_pulsewidth(pi_handle, pin, value)
    end

    # CMD = 17
    def tone(pin, frequency, duration=nil)
      pin_mask = 1 << pin
      half_wavelength = (500000.0 / frequency).round
      new_wave
      wave.tx_stop
      wave.clear
      wave.add_new
      wave.add_generic [
        wave.pulse(pin_mask, 0x00, half_wavelength),
        wave.pulse(0x00, pin_mask, half_wavelength)                  
      ]
      wave_id = wave.create
      
      # Temporary workaround while Wave#send_repeat gets fixed.
      Pigpio::IF.wave_send_repeat(@pi_handle, wave_id)
      # wave.send_repeat(wave_id)
    end

    # CMD = 18
    def no_tone(pin)
      stop_wave
    end

    # CMD = 33
    def i2c_search
      found_string = ""

      # Try to read one byte from each address.
      (0..127).each do |address|
        open_i2c(1, address)
        byte = Pigpio::IF.i2c_read_byte(pi_handle, i2c_handle)
        # Add to the string colon separated if byte was valid.
        found_string << "#{address}:" if byte >= 0
      end

      # Remove trailing colon.
      found_string.chop! unless found_string.empty?

      # Update the bus as if message came from microcontroller.
      self.update(2, found_string)
    end

    # CMD = 34
    def i2c_write(address, bytes=[], options={})
      raise ArgumentError, "can't write more than 255 bytes to I2C" if bytes.length > 255

      # Create a command buffer, starting with the raw I2C bytes.
      buffer = bytes.dup

      # Prepend the length command and value.
      buffer.unshift bytes.length
      buffer.unshift 0x07

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
      open_i2c(1, address)
      Pigpio::IF.i2c_zip(pi_handle, i2c_handle, buffer, 0)
      close_i2c
    end

    # CMD = 35
    def i2c_read(address, register, num_bytes, options={})
      raise ArgumentError, "can't read more than 255 bytes to I2C" if num_bytes > 255

      # Command sequence to read bytes.
      buffer = [0x06, num_bytes]

      # If a start register was given, write it first.
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
      open_i2c(1, address)
      bytes = Pigpio::IF.i2c_zip(pi_handle, i2c_handle, buffer, num_bytes)

      # Format the bytes like dino expects from a microcontroller.
      message = bytes.split("").map { |byte| byte.ord.to_s }.join(",")
      message = "#{address}-#{message}"

      # Call update as if it came from pin 2 (I2C1 SDA pin).
      self.update(2, message)
    end

    private

    def get_gpio(pin)
      Pigpio::UserGPIO.new(@pi_handle, pin)
    end
    
    def pwm_clear(pin)
      @pin_pwms[pin] = nil
    end

    attr_reader :pi_handle, :wave, :i2c_handle

    def new_wave
      stop_wave
      @wave = Pigpio::Wave.new(pi_handle)
    end

    def stop_wave
      return unless wave
      wave.tx_stop
      wave.clear
      @wave = nil
    end

    def open_i2c(bus_index, address)
      @i2c_handle = Pigpio::IF.i2c_open(pi_handle, bus_index, address, 0)
      raise StandardError, "I2C error, code #{@i2c_handle}" if @i2c_handle < 0
    end

    def close_i2c
      Pigpio::IF.i2c_close(pi_handle, i2c_handle)
      @i2c_handle = nil
    end
  end
end
