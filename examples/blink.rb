require 'denko/piboard'

board = Denko::PiBoard.new
led = Denko::LED.new(board: board, pin: 272)

led.blink 0.5

sleep
