module Dino
  class PiBoard
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
      # This would return pin's pwm dutycycle. Maybe another method for that?
      # @pin_pwms[pin].dutycycle
      unless @pin_pwms[pin]
        state = get_gpio(pin).read
        self.update(pin, state)
        return state
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
  end
end
