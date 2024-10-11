module Denko
  class PiBoard
    # CMD = 17
    def tone(pin, frequency, duration=nil)
      if @hardware_pwms[pin]
        @hardware_pwms[pin].frequency    = frequency
        @hardware_pwms[pin].duty_percent = 33
        sleep duration if duration
      else
        raise ArgumentError, "maximum software PWM frequency is 10 kHz" if frequency > 10_000
        cycles = 0
        cycles = (frequency * duration).round if duration

        sleep 0.05 while (LGPIO.tx_room(@gpio_handle, pin, LGPIO::TX_PWM) == 0)
        LGPIO.tx_pwm(@gpio_handle, pin, frequency, 33, 0, cycles)
      end
    end

    # CMD = 18
    def no_tone(pin)
      digital_write(pin, HIGH)
    end

    def tone_busy(pin)
      LGPIO.tx_busy(@gpio_handle, pin, LGPIO::TX_PWM)
    end
  end
end
