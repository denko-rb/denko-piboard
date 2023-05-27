#include <ruby.h>
#include <gpiod.h>

#define GPIO_CHIP_NAME "gpiochip0"

static struct gpiod_chip *chip;

// Save mapping of lowest 32 GPIOs to gpiod_line structs.
static struct gpiod_line *lines[32] = { NULL };

// Input and output values.
static int gpio_number;
static int gpio_state;
static int return_value;

static VALUE open_chip(VALUE self) {
  chip = gpiod_chip_open_by_name(GPIO_CHIP_NAME);
  if (!chip) {
    rb_raise(rb_eRuntimeError, "LIBGPIO: Could not open GPIP chip");
    return Qnil;
  }
  return Qnil;
}


static VALUE close_chip(VALUE self) {
  gpiod_chip_close(chip);
  return Qnil;
}


static VALUE open_line_output(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  
  lines[gpio_number] = gpiod_chip_get_line(chip, gpio_number);
  if (!lines[gpio_number]) {
    rb_raise(rb_eRuntimeError, "LIBGPIO: Could not open GPIO line");
    gpiod_chip_close(chip);
    return Qnil;
  }
  
  return_value = gpiod_line_request_output(lines[gpio_number], "LIBGPIO", 0);
  if (return_value < 0) {
    rb_raise(rb_eRuntimeError, "LIBGPIO: Could not rquest output for GPIO line");
    gpiod_chip_close(chip);
    return Qnil;
  }
  
  return Qnil;
}


static VALUE set_state(VALUE self, VALUE gpio, VALUE state) {
  gpio_number = NUM2INT(gpio);
  gpio_state = NUM2INT(state);
  
  return_value = gpiod_line_set_value(lines[gpio_number], gpio_state);
  
  if (return_value < 0) {
    rb_raise(rb_eRuntimeError, "LIBGPIO: Could not set GPIO value");
    gpiod_chip_close(chip);
    return Qnil;
  }

  return state;
}


static VALUE open_line_input(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  
  lines[gpio_number] = gpiod_chip_get_line(chip, gpio_number);
  if (!lines[gpio_number]) {
    rb_raise(rb_eRuntimeError, "LIBGPIO: Could not open GPIO line");
    gpiod_chip_close(chip);
    return Qnil;
  }
  
  return_value = gpiod_line_request_input(lines[gpio_number], "LIBGPIO");
  if (return_value < 0) {
    rb_raise(rb_eRuntimeError, "LIBGPIO: Could not request input for GPIO line");
    gpiod_chip_close(chip);
    return Qnil;
  }
  
  return Qnil;
}


static VALUE get_state(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  
  return_value = gpiod_line_get_value(lines[gpio_number]);
  
  if (return_value < 0) {
    rb_raise(rb_eRuntimeError, "LIBGPIO: Could not set GPIO value");
    gpiod_chip_close(chip);
    return Qnil;
  }
  
  return INT2NUM(return_value);
}


static VALUE close_line(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  gpiod_line_release(lines[gpio_number]);
  lines[gpio_number] = NULL;  
  return Qnil;
}

void Init_libgpio(void) {
  VALUE mDino    = rb_define_module("Dino");
  VALUE mLIBGPIO = rb_define_module_under(mDino, "LIBGPIO");
  rb_define_singleton_method(mLIBGPIO, "open_chip",        open_chip,        0);
  rb_define_singleton_method(mLIBGPIO, "close_chip",       close_chip,       0);
  rb_define_singleton_method(mLIBGPIO, "open_line_output", open_line_output, 1);
  rb_define_singleton_method(mLIBGPIO, "set_state",        set_state,        2);
  rb_define_singleton_method(mLIBGPIO, "open_line_input",  open_line_input,  1);
  rb_define_singleton_method(mLIBGPIO, "get_state",        get_state,        1);
  rb_define_singleton_method(mLIBGPIO, "close_line",       close_line,       1);
}
