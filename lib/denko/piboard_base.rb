require 'denko'
require 'pigpio'

module Denko
  class PiBoard
    include Pigpio::Constant
      
    attr_reader :high, :low, :pwm_high

    def initialize
      # On 64-bit systems there's a pigpio bug where wavelengths are doubled.
      @aarch64 = RUBY_PLATFORM.match(/aarch64/)

      # Pin state
      @pins          = []
      @pwms          = []

      # Listener state
      @pin_listeners  = []
      @listen_mutex   = Mutex.new
      @listen_states  = Array.new(32) { 0 }
      @listen_thread  = nil
      @listen_reading = 0
      
      # PiGPIO callback state. Unused for now.
      @pin_callbacks = []

      # Logic levels
      @low           = 0
      @high          = 1
      @pwm_high      = 255

      # Use the pigpiod interface directly.
      @pi_handle = Pigpio::IF.pigpio_start
      exit(-1) if @pi_handle < 0
      
      # Open the libgpiod interface too.
      Denko::GPIOD.open_chip
    end

    def finish_write
      Pigpio::IF.pigpio_stop(@pi_handle)
      Denko::GPIOD.close_chip
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
