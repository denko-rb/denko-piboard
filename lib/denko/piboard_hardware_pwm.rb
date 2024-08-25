module Denko
  class PiBoard
    def pwmchip_and_channel_from_pin(pin)
      @pwmchips.each do |chip_index, channel_hash|
        channel_hash.each do |channel, gpio|
          return [chip_index, channel] if gpio == pin
        end
      end
      return nil
    end

    def hardware_pwm_from_pin(pin)
      # Return existing instance, if any, for this GPIO.
      pwm = @hardware_pwms[pin]
      return pwm if pwm

      # Free it in lgpio, in case previously used there.
      LGPIO.gpio_free(@gpio_handle, pin)

      # See if the pin maps to a pwmchip and channel.
      chip_index, channel = pwmchip_and_channel_from_pin(pin)
      raise "GPIO: #{pin} not mapped to hardware PWM channel" unless (chip_index && channel)

      # Create HardwarePWM instance if it does.
      pwm = LGPIO::HardwarePWM.new(chip_index, channel, frequency: 1000)
      @hardware_pwms[pin] = pwm
      return pwm
    end
  end
end
