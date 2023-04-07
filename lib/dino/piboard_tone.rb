module Dino
  class PiBoard
    # CMD = 17
    def tone(pin, frequency, duration=nil)
      pin_mask = 1 << pin
      half_wavelength = (500000.0 / frequency).round
      new_wave
      wave.tx_stop
      wave.clear
      wave.add_new
      wave.add_generic [
        wave.pulse(pin_mask, 0x00, half_wavelength),
        wave.pulse(0x00, pin_mask, half_wavelength)                  
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
