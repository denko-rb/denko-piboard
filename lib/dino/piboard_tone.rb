module Dino
  class PiBoard
    # CMD = 17
    def tone(pin, frequency, duration=nil)
      # 32-bit mask where only the bit corresponding to the GPIO in use is set.
      pin_mask = 1 << pin

      if @aarch64
        # pigpio doubles wave times on 64-bit systems for some reason. Halve it to compensate.
        half_wave_time = (250000.0 / frequency).round
      else
        # This is the true halve wave time.
        half_wave_time = (500000.0 / frequency).round
      end

      # Standard wave setup.
      new_wave
      wave.tx_stop
      wave.clear
      wave.add_new

      # Build wave with a single cycle that will repeat.
      wave.add_generic [
        wave.pulse(pin_mask, 0x00, half_wave_time),
        wave.pulse(0x00, pin_mask, half_wave_time)                  
      ]
      wave_id = wave.create

      # Temporary workaround while Wave#send_repeat gets fixed.
      Pigpio::IF.wave_send_repeat(@pi_handle, wave_id)
      # wave.send_repeat(wave_id)
    end

    # CMD = 18
    def no_tone(pin)
      stop_wave
    end
  end
end
