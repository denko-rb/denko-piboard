require 'timeout'

module Dino
  class PiBoard    
    def pulse_read(pin, reset: false, reset_time: 0, pulse_limit: 100, timeout: 200)
      # Validation
      raise ArgumentError, "error in reset: #{reset}. Should be either #{high} or #{low}"         if reset && ![high, low].include?(reset)
      raise ArgumentError, "errror in reset_time: #{reset_time}. Should be 0..65535 microseconds" if (reset_time < 0) || (reset_time > 0xFFFF)
      raise ArgumentError, "errror in pulse_limit: #{pulse_limit}. Should be 0..255 pulses"       if (pulse_limit < 0) || (pulse_limit > 0xFF)
      raise ArgumentError, "errror in timeout: #{timeout}. Should be 0..65535 milliseconds"       if (pulse_limit < 0) || (pulse_limit > 0xFF)

      if reset
        # Reset pulse will be captured as the first 2 edges.
        expected_edges = pulse_limit + 2 
      else
        # First edge is a starting reference, so store 1 extra.
        expected_edges = pulse_limit + 1
      end

      # Storage for absolute tick time of each edge received from pigpio.
      edges      = Array.new(expected_edges) {0}
      edge_index = 0

      # Switch to input mode immediately if no reset.
      set_pin_mode(pin, :input) unless reset

      # Add callback to catch edges.
      callback = get_gpio(pin).callback(EITHER_EDGE) do |tick, level, pin_cb|
        edges[edge_index] = tick
        edge_index += 1
        callback.cancel if edge_index == expected_edges
      end

      # If using reset pulse, do it, and the mode switch, while the callback is active.
      if reset
        set_pin_mode(pin, :output)
        Dino::GPIOD.set_value(pin, reset)
        sleep(reset_time / 1000000.0)

        # Set pull to opposite direction of reset.
        if (reset == low)
          set_pin_mode(pin, :input_pullup)
        else
          set_pin_mode(pin, :input_pulldown)
        end
      end

      # Wait for pulses or timeout.
      begin
        Timeout::timeout(timeout / 1000.0) do
          loop do
            edge_index == expected_edges ? break : sleep(0.001)
          end
        end
      rescue Timeout::Error
        # Allow less than pulse_limit to be read.
      end
      callback.cancel

      # Ignore the first 2 edges (enable pulse) if reset used, 1 edge (starting reference) if not.
      pulse_offset = reset ? 2 : 1
      pulse_count  = edge_index - pulse_offset
      pulses       = Array.new(pulse_count) {0}

      # Convert from edge times to pulses.
      i = 0
      while i < pulse_count
        pulses[i] = edges[i+pulse_offset] - edges[i+pulse_offset-1]
        i += 1
      end

      # Format pulses as if coming from a microcontroller, and update the component.
      self.update(pin, pulses.join(","))
    end
  end
end
