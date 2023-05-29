module Dino
  class PiBoard
    # CMD = 0
    def set_pin_mode(pin, mode=:input, glitch_time=nil)
      pwm_clear(pin)
      gpio = get_gpio(pin)

      # Output
      if mode.to_s.match /output/
        gpio.mode = PI_OUTPUT
        
        # Use pigpiod for setup, but still open it for libgpiod access.
        Dino::GPIOD.open_line_output(pin)

      # Input
      else
        gpio.mode = PI_INPUT

        # State change valid only if steady for this many microseconds.
        # Only applies to callbacks hooked through pigpiod
        if glitch_time
          gpio.glitch_filter(glitch_time)
        end

        # Pull down/up/none
        if mode.to_s.match /pulldown/
          gpio.pud = PI_PUD_DOWN
        elsif mode.to_s.match /pullup/
          gpio.pud = PI_PUD_UP
        else
          gpio.pud = PI_PUD_OFF
        end
        
        # Use pigpiod for setup, but still open it for libgpiod access.
        Dino::GPIOD.open_line_input(pin)
      end
    end

    # CMD = 1
    def digital_write(pin, value)
      pwm_clear(pin)
      Dino::GPIOD.set_state(pin, value)
    end
    
    # CMD = 2
    def digital_read(pin)
      unless @pwms[pin]
        state = Dino::GPIOD.get_state(pin)
        self.update(pin, state)
        return state
      end
    end
    
    # Same as above, but doesn't check for pwm or trigger callbacks.
    def digital_read_raw(pin)
      Dino::GPIOD.get_state(pin)
    end
    
    # CMD = 3
    def pwm_write(pin, value)
      # Disable servo if necessary.
      pwm_clear(pin) if @pwms[pin] == :servo

      unless @pwms[pin]
        @pwms[pin] = get_gpio(pin).pwm
        @pwms[pin].frequency = 1000
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
  end
end
