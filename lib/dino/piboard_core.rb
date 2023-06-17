module Dino
  class PiBoard
    # CMD = 0
    def set_pin_mode(pin, mode=:input, glitch_time=nil)
      # Close the line in libgpiod, if was already open.
      Dino::GPIOD.close_line(pin)

      pwm_clear(pin)
      gpio = get_gpio(pin)

      # Output
      if mode.to_s.match /output/
        gpio.mode = PI_OUTPUT
        
        # Use pigpiod for setup, but still open line in libgpiod.
        Dino::GPIOD.open_line_output(pin)

      # Input
      else
        gpio.mode = PI_INPUT

        # State change valid only if steady for this many microseconds.
        # Only applies to callbacks hooked through pigpiod.
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
        
        # Use pigpiod for setup, but still open line in libgpiod.
        Dino::GPIOD.open_line_input(pin)
      end
    end

    # CMD = 1
    def digital_write(pin, value)
      pwm_clear(pin)
      Dino::GPIOD.set_value(pin, value)
    end
    
    # CMD = 2
    def digital_read(pin)
      unless @pwms[pin]
        state = Dino::GPIOD.get_value(pin)
        self.update(pin, state)
        return state
      end
    end
    
    # CMD = 3
    def pwm_write(pin, value)
      # Disable servo if necessary.
      pwm_clear(pin) if @pwms[pin] == :servo

      unless @pwms[pin]
        @pwms[pin] = get_gpio(pin).pwm
        @pwms[pin].frequency = 1000
      end
      @pwms[pin].dutycycle = value
    end

    # PiGPIO native callbacks. Unused now.
    def set_alert(pin, state=:off, options={})
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

    # CMD = 6
    def set_listener(pin, state=:off, options={})
      # Listener on
      if state == :on && !@pin_listeners.include?(pin)
        add_listener(pin)
      else
        remove_listener(pin)
      end
    end

    def digital_listen(pin, divider=4)
      set_listener(pin, :on, {})
    end

    def stop_listener(pin)
      set_listener(pin, :off)
    end

    def add_listener(pin)
      @listen_mutex.synchronize do
        @pin_listeners |= [pin]
        @pin_listeners.sort!
        @listen_states[pin] = Dino::GPIOD.get_value(pin)
      end
      start_listen_thread
    end
    
    def remove_listener(pin)
      @listen_mutex.synchronize do
        @pin_listeners.delete(pin)
        @listen_states[pin] = nil
      end
    end
    
    def start_listen_thread
      return if @listen_thread
      
      @listen_thread = Thread.new do
        #
        # @listen_monitor_thread will adjust sleep time dyanmically,
        # targeting even timing of 1 millisecond between loops.
        #
        @listen_count = 0
        @listen_sleep = 0.001
        start_time = Time.now

        loop do
          @listen_mutex.synchronize do
            @pin_listeners.each do |pin|
              @listen_reading = Dino::GPIOD.get_value(pin)
              self.update(pin, @listen_reading) if (@listen_reading != @listen_states[pin])
              @listen_states[pin] = @listen_reading
            end
          end
          @listen_count += 1
          sleep(@listen_sleep)
        end
      end

      @listen_monitor_thread = Thread.new do
        loop do
          # Sample the listen rate over 5 seconds.
          time1  = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          count1 = @listen_count
          sleep(5)
          time2  = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          count2 = @listen_count
          
          # Quick maths.
          loops = count2 - count1
          time  = time2 - time1
          active_time_per_loop = (time - (loops * @listen_sleep)) / loops

          # Target 1 millisecond.
          @listen_sleep = 0.001 - active_time_per_loop
        end
      end
    end
    
    def stop_listen_thread
      @listen_monitor_thread.kill
      @listen_monitor_thread = nil
      @listen_thread.kill
      @listen_thread = nil
    end
  end
end
