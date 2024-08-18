module Denko
  class PiBoard
    # CMD = 10
    def servo_toggle(pin, value=:off, options={})
      pwm = @hardware_pwms[pin]
      if (pwm && value == :off)
        pwm.duty_cycle = 0
        pwm.disable
      elsif (value == :on)
        chip, channel = gpio_to_pwm_channel(pin)
        raise "GPIO: #{pin} not mapped to a hardware PWM channel. Cannot start servo." unless (chip && channel)
        pwm = LGPIO::HardwarePWM.new(chip, channel, frequency: 50)
        @hardware_pwms[pin] = pwm
      end
    end

    # CMD = 11
    def servo_write(pin, value=0)
      @hardware_pwms[pin].duty_us = value
    end
  end
end
