module Denko
  class PiBoard
    def hardware_pwms
      @hardware_pwms ||= []
    end

    def hardware_pwm_from_pin(pin)
      pwm = hardware_pwms[pin]
      return pwm if pwm

      raise StandardError, "no PWM device in board map for pin #{pin}" unless map[:pwms][pin]

      pwmchip = map[:pwms][pin][:pwmchip]
      channel = map[:pwms][pin][:channel]
      pwm = LGPIO::HardwarePWM.new(pwmchip, channel, frequency: 1000)
      hardware_pwms[pin] = pwm
    end
  end
end
