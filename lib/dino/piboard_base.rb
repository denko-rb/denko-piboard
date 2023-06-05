require 'dino'
require 'pigpio'

module Dino
  class PiBoard
    include Pigpio::Constant
      
    attr_reader :high, :low, :pwm_high

    def initialize
      @pins          = []
      @pin_callbacks = []
      @pwms          = []

      @low           = 0
      @high          = 1
      @pwm_high      = 255

      # Use the pigpiod interface directly.
      @pi_handle = Pigpio::IF.pigpio_start
      exit(-1) if @pi_handle < 0
      
      # Start the libgpiod interface too.
      Dino::GPIOD.open_chip
    end

    def finish_write
      Pigpio::IF.pigpio_stop(@pi_handle)
      Dino::GPIOD.close_chip
    end

    #
    # Use standard Subcomponents behavior.
    #
    include Behaviors::Subcomponents

    def update(pin, message, time=nil)
      if single_pin_components[pin]
        single_pin_components[pin].update(message)
      end
    end

    private

    attr_reader :pi_handle, :wave

    def get_gpio(pin)
      @pins[pin] ||= Pigpio::UserGPIO.new(@pi_handle, pin)
    end
    
    def pwm_clear(pin)
      @pwms[pin] = nil
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
