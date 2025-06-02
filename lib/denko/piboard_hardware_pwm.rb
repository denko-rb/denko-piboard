module Denko
  class PiBoard
    # Check if a GPIO number is bound to a hardware PWM.
    def pin_is_pwm?(pin)
      map[:pwms][pin]
    end

    def hardware_pwms
      @hardware_pwms ||= []
    end

    def hardware_pwm_from_pin(pin, options={})
      # Find existing hardware PWM, change the frequency if needed, then return it.
      frequency = options[:frequency]
      pwm = hardware_pwms[pin]
      if pwm
        pwm.frequency = frequency if (frequency && pwm.frequency != frequency)
        return pwm
      end

      # Make sure it's in the board map before trying to use it.
      raise StandardError, "no hardware PWM in board map for pin #{pin}" unless map[:pwms][pin]

      # Make a new hardware PWM.
      pwmchip = map[:pwms][pin][:pwmchip]
      channel = map[:pwms][pin][:channel]
      frequency ||= 1000
      pwm = LGPIO::HardwarePWM.new(pwmchip, channel, frequency: frequency)
      hardware_pwms[pin] = pwm
    end
  end
end
