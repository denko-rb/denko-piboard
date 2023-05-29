require 'mkmf'

#
# Need libgpiod-dev installed.
#   sudo apt install libgpiod-dev
#
$libs += " -lgpiod"

create_makefile('gpiod/gpiod')
