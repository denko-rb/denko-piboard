module Denko
  class PiBoard
    def infrared_emit(pin, frequency, pulses)
      # Main gem uses frequency in kHz. Set it in Hz.
      pwm = hardware_pwm_from_pin(pin)
      pwm.frequency = (frequency * 1000)

      # The actual strings for the sysfs PWM interface.
      duty_path = "#{pwm.path}duty_cycle"
      duty_ns   = (0.333333 * pwm.period).round.to_s

      pwm.tx_wave_ook(duty_path, duty_ns, pulses)
    end
  end
end
