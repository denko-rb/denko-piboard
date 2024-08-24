module Denko
  class PiBoard
    def show_ws2812(pin, pixel_buffer)
      if @spis.values.first[:mosi] == pin
        @ws2812_handle ||= LGPIO.spi_open(@spis.keys.first, 0, 2_400_000, 0)
        LGPIO.spi_ws2812_write(@ws2812_handle, pixel_buffer)
      else
        raise ArgumentError, "PiBoard only supports WS2812 output on a SPI MOSI pin"
      end
    end
  end
end
