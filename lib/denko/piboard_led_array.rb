module Denko
  class PiBoard
    def show_ws2812(pin, pixel_buffer)
      if spi_index = map[:spis].keys.first
        @ws2812_handle ||= LGPIO.spi_open(spi_index, 0, 2_400_000, 0)
        LGPIO.spi_ws2812_write(@ws2812_handle, pixel_buffer)
      else
        raise ArgumentError, "WS2812 on PiBoard requires exclusive access to the first :spi device defined in your board map and outputs on its :mosi pin"
      end
    end
  end
end
