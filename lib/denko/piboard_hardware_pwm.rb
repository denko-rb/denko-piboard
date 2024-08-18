module Denko
  class PiBoard
    def pwm_chip_and_channel_from_pin(pin)
      @pwm_chips.each do |chip|
        channel = chip[:gpios][pin]
        return [chip[:index], channel] if channel
      end
      return [nil, nil]
    end

    def pwm_instance_from_pin(pin)
      # Return existing instance, if any, for this GPIO.
      pwm = @hardware_pwms[pin]
      return pwm if pwm

      # See if the pin maps to a pwmchip and channel.
      chip_index, channel = pwm_chip_and_channel_from_pin(pin)
      raise "GPIO: #{pin} not mapped to hardware PWM channel" unless (chip_index && channel)

      # Create HardwarePWM instance if it does.
      pwm = LGPIO::HardwarePWM.new(chip_index, channel, frequency: 1000)
      @hardware_pwms[pin] = pwm
      return pwm
    end
  end
end
