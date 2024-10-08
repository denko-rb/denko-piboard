require 'timeout'

module Denko
  class PiBoard
    def hcsr04_read(echo_pin, trigger_pin)
      microseconds = LGPIO.gpio_read_ultrasonic(@gpio_handle, trigger_pin, echo_pin, 10)
      self.update(echo_pin, microseconds.to_s)
    end

    def pulse_read(pin, reset: false, reset_time: 0, pulse_limit: 100, timeout: 200)
      # Validation
      raise ArgumentError, "error in reset: #{reset}. Should be either #{high} or #{low}"         if reset && ![high, low].include?(reset)
      raise ArgumentError, "errror in reset_time: #{reset_time}. Should be 0..65535 microseconds" if (reset_time < 0) || (reset_time > 0xFFFF)
      raise ArgumentError, "errror in pulse_limit: #{pulse_limit}. Should be 0..255 pulses"       if (pulse_limit < 0) || (pulse_limit > 0xFF)
      raise ArgumentError, "errror in timeout: #{timeout}. Should be 0..65535 milliseconds"       if (timeout < 0) || (timeout > 0xFFFF)

      pulses = LGPIO.gpio_read_pulses_us(@gpio_handle, pin, reset_time, reset, pulse_limit, timeout)
      if pulses.class == Array
        self.update(pin, pulses.join(","))
      elsif pulse.class == Integer
        raise "could not read pulses from GPIO #{pin}. LGPIO error: #{pulses}"
      end
    end
  end
end
