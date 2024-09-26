module Denko
  class PiBoard
    INPUT_MODES  = [:input, :input_pullup, :input_pulldown]
    OUTPUT_MODES = [:output, :output_pwm, :output_open_drain, :output_open_source]
    PIN_MODES = INPUT_MODES + OUTPUT_MODES

    # CMD = 0
    def set_pin_mode(pin, mode=:input, options={})
      # Is the mode valid?
      unless PIN_MODES.include?(mode)
        raise ArgumentError, "cannot set mode: #{mode}. Should be one of: #{PIN_MODES.inspect}"
      end

      # IF PWM output requested, and GPIO has hardware PWM channel, use it.
      if (mode == :output_pwm) && pwmchip_and_channel_from_pin(pin)
        return hardware_pwm_from_pin(pin)
      end

      # Attempt to free the pin.
      LGPIO.gpio_free(@gpio_handle, pin)

      # Is the pin in use by the kernel? Hardware PWM counts too.
      if ((LGPIO.gpio_get_mode(@gpio_handle, pin) & 0b1) == 1)
        if pwmchip_and_channel_from_pin(pin)
          if (mode == :output)
            # Abstract digital I/O with 100% and 0% duty cycles.
            puts "WARNING: using hardware PWM on pin: #{pin} as GPIO. Performance will be worse."
            return hardware_pwm_from_pin(pin)
          else
            raise "pin: #{pin} is in hadrware PWM mode. Can only be :output or :output_pwm mode until reboot"
          end
        else
          raise "pin: #{pin} in use by kernel (or does not exist). Cannot be used for GPIO"
        end
      end

      # Normal GPIO setup
      if OUTPUT_MODES.include?(mode)
        flags  = LGPIO::SET_PULL_NONE
        flags  = LGPIO::SET_OPEN_DRAIN  if mode == :output_open_drain
        flags  = LGPIO::SET_OPEN_SOURCE if mode == :output_open_source
        result = LGPIO.gpio_claim_output(@gpio_handle, flags, pin, LOW)
      else
        flags  = LGPIO::SET_PULL_NONE
        flags  = LGPIO::SET_PULL_UP   if mode == :input_pullup
        flags  = LGPIO::SET_PULL_DOWN if mode == :input_pulldown
        result = LGPIO.gpio_claim_input(@gpio_handle, flags, pin)
      end
      raise "could not claim GPIO #{pin}. LGPIO error: #{result}" if result < 0

      # Cache these in case another method needs to reset the pin.
      @pin_configs[pin] = @pin_configs[pin].to_h.merge(mode: mode)
    end

    def set_pin_debounce(pin, debounce_time)
      return unless debounce_time
      result = LGPIO.gpio_set_debounce(@gpio_handle, pin, debounce_time)
      raise "could not set debounce for GPIO #{pin}. LGPIO error: #{result}" if result < 0
      @pin_configs[pin] = @pin_configs[pin].to_h.merge(debounce_time: debounce_time)
    end

    # CMD = 1
    def digital_write(pin, value)
      if @hardware_pwms[pin]
        @hardware_pwms[pin].duty_percent = (value == 0) ? 0 : 100
      else
        LGPIO.gpio_write(@gpio_handle, pin, value)
      end
    end

    # CMD = 2
    def digital_read(pin)
      return @hardware_pwms[pin].duty_percent if @hardware_pwms[pin]
      state = LGPIO.gpio_read(@gpio_handle, pin)
      self.update(pin, state)
      return state
    end

    # CMD = 3
    def pwm_write(pin, duty)
      if @hardware_pwms[pin]
        @hardware_pwms[pin].frequency    = 1000
        @hardware_pwms[pin].duty_percent = duty
      else
        LGPIO.tx_pwm(@gpio_handle, pin, 1000, duty, 0, 0)
      end
    end

    # CMD = 4
    def dac_write(pin, value)
      raise "PiBoard#dac_write not implemented"
    end

    # CMD = 5
    def analog_read(pin, negative_pin=nil, gain=nil, sample_rate=nil)
      raise "PiBoard#analog_read not implemented"
    end

    # CMD = 6
    def set_listener(pin, state=:off, options={})
      # Validate listener is digital only.
      options[:mode] ||= :digital
      unless options[:mode] == :digital
        raise ArgumentError, "error in mode: #{options[:mode]}. Should be one of: [:digital]"
      end

      # Validate state.
      unless (state == :on) || (state == :off)
        raise ArgumentError, "error in state: #{options[:state]}. Should be one of: [:on, :off]"
      end

      # Only way to stop getting alerts is to free the GPIO.
      LGPIO.gpio_free(@gpio_handle, pin)

      # Reclaim it as input if needed.
      config   = @pin_configs[pin]
      config ||= { mode: :input, debounce_time: nil } if state == :on
      if config
        set_pin_mode(pin, config[:mode])
        set_pin_debounce(pin, config[:debounce_time])
      end

      if state == :on
        LGPIO.gpio_claim_alert(@gpio_handle, 0, LGPIO::BOTH_EDGES, pin)
        start_alert_thread unless @alert_thread
      end
    end

    def digital_listen(pin, divider=4)
      set_listener(pin, :on, {})
    end

    def stop_listener(pin)
      set_listener(pin, :off)
    end

    def start_gpio_reports
      return if @reporting_started
      LGPIO.gpio_start_reporting
      @reporting_started = true
    end

    def start_alert_thread
      start_gpio_reports
      @alert_thread = Thread.new do
        loop do
          report = LGPIO.gpio_get_report
          if report
            update(report[:gpio], report[:level])
          else
            sleep 0.001
          end
        end
      end
    end

    def stop_alert_thread
      Thread.kill(@alert_thread) if @alert_thread
      @alert_thread = nil
    end
  end
end
