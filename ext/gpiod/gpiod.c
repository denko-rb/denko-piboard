#include <ruby.h>
#include <gpiod.h>

#define GPIO_CHIP_NAME "gpiochip0"

static struct gpiod_chip *chip;

// Save mapping of lowest 32 GPIOs to gpiod_line structs.
static struct gpiod_line *lines[32] = { NULL };

// Input and output values.
static int gpio_number;
static int gpio_value;
static int return_value;

static VALUE open_chip(VALUE self) {
  chip = gpiod_chip_open_by_name(GPIO_CHIP_NAME);
  if (!chip) {
    rb_raise(rb_eRuntimeError, "libgpiod error: Could not open GPIO chip");
    return Qnil;
  }
  return Qnil;
}

static VALUE close_chip(VALUE self) {
  gpiod_chip_close(chip);
  return Qnil;
}

static void validate_gpio_number(int gpio_number) {
  if ((gpio_number < 0) || (gpio_number > 31)) {
    VALUE error_message = rb_sprintf("libgpiod error: GPIO line (%d) out of range. Valid range is 0..31", gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
  }
}

static void validate_gpio_value(int value) {
  if (!((value == 0) || (value == 1))) {
    VALUE error_message = rb_sprintf("libgpiod error: GPIO value (%d) out of range. Valid values are 0 or 1", value);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
  }
}

static VALUE open_line_output(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  validate_gpio_number(gpio_number);

  lines[gpio_number] = gpiod_chip_get_line(chip, gpio_number);
  if (!lines[gpio_number]) {
    gpiod_chip_close(chip);
    VALUE error_message = rb_sprintf("libgpiod error: Could not get GPIO line %d", gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
    return Qnil;
  }
  
  return_value = gpiod_line_request_output(lines[gpio_number], "GPIOD_RB", 0);
  if (return_value < 0) {
    gpiod_chip_close(chip);
    VALUE error_message = rb_sprintf("libgpiod error: Could not request output for GPIO line %d", gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
    return Qnil;
  }
  
  return Qnil;
}

static VALUE set_value(VALUE self, VALUE gpio, VALUE value) {
  gpio_number = NUM2INT(gpio);
  validate_gpio_number(gpio_number);
  gpio_value = NUM2INT(value);
  validate_gpio_value(gpio_value);

  return_value = gpiod_line_set_value(lines[gpio_number], gpio_value);
  
  if (return_value < 0) {
    gpiod_chip_close(chip);
    VALUE error_message = rb_sprintf("libgpiod error: Could not set value %d on GPIO line %d", gpio_value, gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
    return Qnil;
  }

  return value;
}

static VALUE open_line_input(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  validate_gpio_number(gpio_number);
  
  lines[gpio_number] = gpiod_chip_get_line(chip, gpio_number);
  if (!lines[gpio_number]) {
    gpiod_chip_close(chip);
    VALUE error_message = rb_sprintf("libgpiod error: Could not get GPIO line %d", gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
    return Qnil;
  }
  
  return_value = gpiod_line_request_input(lines[gpio_number], "GPIOD_RB");
  if (return_value < 0) {
    gpiod_chip_close(chip);
    VALUE error_message = rb_sprintf("libgpiod error: Could not request input for GPIO line %d", gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
    return Qnil;
  }
  
  return Qnil;
}

static VALUE get_value(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  validate_gpio_number(gpio_number);
  
  return_value = gpiod_line_get_value(lines[gpio_number]);
  
  if (return_value < 0) {
    gpiod_chip_close(chip);
    VALUE error_message = rb_sprintf("libgpiod error: Could not get value from GPIO line %d", gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
    return Qnil;
  }
  
  return INT2NUM(return_value);
}

static VALUE close_line(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  validate_gpio_number(gpio_number);

  // Only try to close the line if it was opened before.
  if (lines[gpio_number] == NULL) return Qnil;

  gpiod_line_release(lines[gpio_number]);
  lines[gpio_number] = NULL;  
  return Qnil;
}

static VALUE set_value_raw(VALUE self, VALUE gpio, VALUE value) {
  gpio_number = NUM2INT(gpio);
  gpio_value = NUM2INT(value);

  return_value = gpiod_line_set_value(lines[gpio_number], gpio_value);
  
  if (return_value < 0) {
    gpiod_chip_close(chip);
    VALUE error_message = rb_sprintf("libgpiod error: Could not set value %d on GPIO line %d", gpio_value, gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
    return Qnil;
  }
  return value;
}

static VALUE get_value_raw(VALUE self, VALUE gpio) {
  gpio_number = NUM2INT(gpio);
  
  return_value = gpiod_line_get_value(lines[gpio_number]);
  
  if (return_value < 0) {
    gpiod_chip_close(chip);
    VALUE error_message = rb_sprintf("libgpiod error: Could not get value from GPIO line %d", gpio_number);
    rb_raise(rb_eRuntimeError, "%s", StringValueCStr(error_message));
    return Qnil;
  }
  return INT2NUM(return_value);
}

void Init_gpiod(void) {
  VALUE mDino  = rb_define_module("Dino");
  VALUE mGPIOD = rb_define_module_under(mDino, "GPIOD");
  rb_define_singleton_method(mGPIOD, "open_chip",        open_chip,        0);
  rb_define_singleton_method(mGPIOD, "close_chip",       close_chip,       0);
  rb_define_singleton_method(mGPIOD, "open_line_output", open_line_output, 1);
  rb_define_singleton_method(mGPIOD, "set_value",        set_value,        2);
  rb_define_singleton_method(mGPIOD, "open_line_input",  open_line_input,  1);
  rb_define_singleton_method(mGPIOD, "get_value",        get_value,        1);
  rb_define_singleton_method(mGPIOD, "close_line",       close_line,       1);

  // These do no validation.
  rb_define_singleton_method(mGPIOD, "set_value_raw",    set_value_raw,    2);
  rb_define_singleton_method(mGPIOD, "get_value_raw",    get_value_raw,    1);
}
