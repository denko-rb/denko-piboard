require 'pigpio_ffi'
require 'dino'

module Dino
  class PiBoard
    attr_reader :components, :high, :low

    def initialize
      @components = []

      # Sample every 10us, using PCM peripheral. Keeps CPU usage down.
      PiGPIO.gpioCfgClock(10, 1, 0)    
      PiGPIO.gpioInitialise
    
      @low  = 0
      @high = 1
    end

    def finish_write
      PiGPIO.gpioTerminate
    end

    def update(pin, message, time)
      update_component(pin, message)
    end

    def update_component(pin, message)
      @components.each do |part|
        part.update(message) if part.pin.to_i == pin
      end
    end

    def add_component(component)
      @components << component
    end

    def remove_component(component)
      # component.stop if component.methods.include? :stop
      @components.delete(component)
    end

    # CMD = 0
    def set_pin_mode(pin, mode=:input)
      # Output
      if mode.to_s.match /output/
        PiGPIO.gpioSetMode(pin, 1)

      # Input
      else  
        PiGPIO.gpioSetMode(pin, 0)
        # Only respond if level has been stable for 90us.
        PiGPIO.gpioGlitchFilter(pin, 90)      

        # Pull down/up/none
        if mode.to_s.match /pulldown/
          PiGPIO.gpioSetPullUpDown(pin, 1)
        elsif mode.to_s.match /pullup/
          PiGPIO.gpioSetPullUpDown(pin, 2)
        else
          PiGPIO.gpioSetPullUpDown(pin, 0)
        end
      end
    end

    # CMD = 1
    def digital_write(pin, value)
      PiGPIO.gpioWrite(pin, value)
    end
    
    # CMD = 2
    def digital_read(pin)
      update(pin, PiGPIO.gpioRead(pin))
    end

    # CMD = 3
    def pwm_write(pin, value)
      PiGPIO.gpioPWM(pin, value)
    end

    # CMD = 6
    def set_listener(set_pin, state=:off, options={})
      if state == :on
        PiGPIO.gpioSetAlertFunc(set_pin) do |pin, message, time|
          update(pin, message, time)
        end
      else
        PiGPIO._gpioSetAlertFunc(pin, nil)
      end
    end

    def digital_listen(pin, divider=4)
      set_listener(pin, :on, {})
    end

    def stop_listener(pin)
      set_listener(pin, :off)
    end
  end
end
