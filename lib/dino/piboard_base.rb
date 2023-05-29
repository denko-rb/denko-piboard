require 'dino'
require 'pigpio'

module Dino
  class PiBoard
    include Pigpio::Constant
      
    attr_reader :components, :high, :low, :pwm_high

    def initialize
      @components = []
      @pin_callbacks = []
      @pin_pwms = []
      @pins = []
      
      @low  = 0
      @high = 1
      @pwm_high = 255

      # Use the pigpiod interface directly.
      @pi_handle = Pigpio::IF.pigpio_start
      
      # Start the libgpiod interface too.
      Dino::GPIOD.open_chip
          
      exit(-1) if @pi_handle < 0
    end

    def convert_pin(pin)
      pin.to_i
    end

    def finish_write
      Pigpio::IF.pigpio_stop(@pi_handle)
      Dino::GPIOD.close_chip
    end

    def update(pin, message, time=nil)
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
      component.stop if component.methods.include? :stop
      @components.delete(component)
    end

    private

    attr_reader :pi_handle, :wave

    def get_gpio(pin)
      @pins[pin] ||= Pigpio::UserGPIO.new(@pi_handle, pin)
    end
    
    def pwm_clear(pin)
      @pin_pwms[pin] = nil
    end

    def new_wave
      stop_wave
      @wave = Pigpio::Wave.new(pi_handle)
    end

    def stop_wave
      return unless wave
      wave.tx_stop
      wave.clear
      @wave = nil
    end
  end
end
