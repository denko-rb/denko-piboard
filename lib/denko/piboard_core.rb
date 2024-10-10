module Denko
  class PiBoard
    REPORT_SLEEP_TIME = 0.001
    INPUT_MODES  = [:input, :input_pullup, :input_pulldown]
    OUTPUT_MODES = [:output, :output_pwm, :output_open_drain, :output_open_source]
    PIN_MODES = INPUT_MODES + OUTPUT_MODES

    # CMD = 0
    def set_pin_mode(pin, mode=:input, options={})
      # Is the mode valid?
      unless PIN_MODES.include?(mode)
        raise ArgumentError, "cannot set mode: #{mode}. Should be one of: #{PIN_MODES.inspect}"
      end

      # If pin is bound to hardware PWM, allow it to be used as :output_pwm. OR :output.
      if map[:pwms][pin]
        if (mode == :output_pwm)
          return hardware_pwm_from_pin(pin, options)
        elsif (mode == :output)
          puts "WARNING: using hardware PWM on pin #{pin} as GPIO. Will be slower than regular GPIO."
          return hardware_pwm_from_pin(pin, options)
        else
          raise "Pin #{pin} is bound to hardware PWM. It can only be used as :output or :output_pwm"
        end
      end

      # Attempt to free the pin.
      LGPIO.gpio_free(*gpio_tuple(pin))

      # Try to claim the GPIO.
      if OUTPUT_MODES.include?(mode)
        flags  = LGPIO::SET_PULL_NONE
        flags  = LGPIO::SET_OPEN_DRAIN  if mode == :output_open_drain
        flags  = LGPIO::SET_OPEN_SOURCE if mode == :output_open_source
        result = LGPIO.gpio_claim_output(*gpio_tuple(pin), flags, LOW)
      else
        flags  = LGPIO::SET_PULL_NONE
        flags  = LGPIO::SET_PULL_UP   if mode == :input_pullup
        flags  = LGPIO::SET_PULL_DOWN if mode == :input_pulldown
        result = LGPIO.gpio_claim_input(*gpio_tuple(pin), flags)
      end
      raise "could not claim GPIO for pin #{pin}. lgpio C error: #{result}" if result < 0

      pin_configs[pin] = pin_configs[pin].to_h.merge(mode: mode).merge(options)
    end

    def set_pin_debounce(pin, debounce_time)
      return unless debounce_time
      result = LGPIO.gpio_set_debounce(*gpio_tuple(pin), debounce_time)
      raise "could not set debounce for pin #{pin}. lgpio C error: #{result}" if result < 0

      pin_configs[pin] = pin_configs[pin].to_h.merge(debounce_time: debounce_time)
    end

    def digital_write(pin, value)
      if hardware_pwms[pin]
        hardware_pwms[pin].duty_percent = (value == 0) ? 0 : 100
      else
        handle, line = gpio_tuple(pin)
        LGPIO.gpio_write(handle, line, value)
      end
    end

    def digital_read(pin)
      if hardware_pwms[pin]
        state = hardware_pwms[pin].duty_percent
      else
        handle, line = gpio_tuple(pin)
        state = LGPIO.gpio_read(handle, line)
      end
      self.update(pin, state)
      return state
    end

    def pwm_write(pin, duty)
      if hardware_pwms[pin]
        hardware_pwms[pin].duty_percent = duty
      else
        frequency    = pin_configs[pin][:frequency] || 1000
        handle, line = gpio_tuple(pin)
        LGPIO.tx_pwm(handle, line, frequency, duty, 0, 0)
      end
    end

    def dac_write(pin, value)
      raise "PiBoard#dac_write not implemented"
    end

    def analog_read(pin, negative_pin=nil, gain=nil, sample_rate=nil)
      raise "PiBoard#analog_read not implemented"
    end

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
      LGPIO.gpio_free(*gpio_tuple(pin))

      # Reclaim it as input if needed.
      config   = pin_configs[pin]
      config ||= { mode: :input, debounce_time: nil } if state == :on
      if config
        set_pin_mode(pin, config[:mode])
        set_pin_debounce(pin, config[:debounce_time])
      end

      if state == :on
        LGPIO.gpio_claim_alert(*gpio_tuple(pin), 0, LGPIO::BOTH_EDGES)
        start_alert_thread unless @alert_thread
      end
    end

    def digital_listen(pin, divider=4)
      set_listener(pin, :on, {})
    end

    def stop_listener(pin)
      set_listener(pin, :off)
    end

    def start_alert_thread
      start_gpio_reports
      @alert_thread = Thread.new { loop { get_report } }
    end

    def stop_alert_thread
      Thread.kill(@alert_thread) if @alert_thread
      @alert_thread = nil
    end

    def get_report
      report = LGPIO.gpio_get_report
      if report
        if chip = alert_lut[report[:chip]]
          if pin = chip[report[:gpio]]
            update(pin, report[:level])
          end
        end
      else
        sleep 0.001
      end
    end

    def start_gpio_reports
      return if @reporting_started
      LGPIO.gpio_start_reporting
      @reporting_started = true
    end

    def pin_configs
      @pin_configs ||= []
    end
  end
end
