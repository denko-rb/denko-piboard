#
# DO NOT REQUIRE THIS FILE. It is evaluated at runtime, if applicable.
#
# Optimized method overrides when all GPIO pins are on one gpiochip.
#
def digital_write(pin, value)
  if hardware_pwms[pin]
    hardware_pwms[pin].duty_percent = (value == 0) ? 0 : 100
  else
    LGPIO.gpio_write(__GPIOCHIP_SINGLE_HANDLE__, pin, value)
  end
end

def digital_read(pin)
  if hardware_pwms[pin]
    state = hardware_pwms[pin].duty_percent
  else
    state = LGPIO.gpio_read(__GPIOCHIP_SINGLE_HANDLE__, pin)
  end
  self.update(pin, state)
  return state
end

def get_report
  report = LGPIO.gpio_get_report
  if report
    pin = report[:gpio]
    update(pin, report[:level])
  else
    sleep REPORT_SLEEP_TIME
  end
end
