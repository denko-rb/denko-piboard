module Denko
  class PiBoard
    def show_ws2812(pin, pixel_buffer, spi_index:)
      handle = spi_open(spi_index, 2_400_000, 0)
      LGPIO.spi_ws2812_write(handle, pixel_buffer)
      spi_close(handle)
    end
  end
end
