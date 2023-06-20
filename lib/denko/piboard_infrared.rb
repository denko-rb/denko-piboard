module Denko
  class PiBoard
    def infrared_emit(pin, frequency, pulses)
      # 32-bit mask where only the bit corresponding to the GPIO in use is set.
      pin_mask = 1 << pin
      
      # IR frequency given in kHz. Find half wave time in microseconds.
      if @aarch64
        # Compensate for pigpio doubling wave times on 64-bit systems.
        half_wave_time = (250.0 / frequency)
      else
        # True half wave time.
        half_wave_time = (500.0 / frequency)
      end

      # Standard wave setup.
      new_wave
      wave.tx_stop
      wave.clear
      wave.add_new
            
      # Build an array of pulses to add to the wave.
      wave_pulses = []
      pulses.each_with_index do |pulse, index|
        # Even indices send the carrier wave.
        if (index % 2 == 0)
          cycles = (pulse / (half_wave_time * 2)).round
          cycles.times do
            wave_pulses << wave.pulse(pin_mask, 0x00, half_wave_time)
            wave_pulses << wave.pulse(0x00, pin_mask, half_wave_time)
          end
          
        # Odd indices are idle.
        else
          if @aarch64
            # Half idle times for 64-bit systems.
            wave_pulses << wave.pulse(0x00, pin_mask, pulse / 2)
          else
            wave_pulses << wave.pulse(0x00, pin_mask, pulse)
          end
        end
      end      
      wave.add_generic(wave_pulses)
      wave_id = wave.create
      
      # Temporary workaround while Wave#send_once gets fixed.
      Pigpio::IF.wave_send_once(@pi_handle, wave_id)
      # wave.send_once(wave_id)
    end
  end
end
