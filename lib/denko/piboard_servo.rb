module Denko
  class PiBoard
    # CMD = 10
    def servo_toggle(pin, value=:off, options={})
      if value == :off
        pwm_clear(pin)
        digital_write(pin, 0)
      else
        @pwms[pin] = :servo
      end
    end
    
    # CMD = 11
    def servo_write(pin, value=0)
      Pigpio::IF.set_servo_pulsewidth(pi_handle, pin, value)
    end
  end
end
