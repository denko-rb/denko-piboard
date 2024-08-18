module Denko
  class PiBoard
    # CMD = 10
    def servo_toggle(pin, value=:off, options={})
      pwm = pwm_instance_from_pin(pin)
      if (value == :off)
        pwm.duty_cycle = 0
        pwm.disable
      elsif
        pwm.frequency = 50
      end
    end

    # CMD = 11
    def servo_write(pin, value=0)
      @hardware_pwms[pin].duty_us = value
    end
  end
end
