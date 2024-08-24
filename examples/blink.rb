require 'denko/piboard'

PIN = 272

board = Denko::PiBoard.new
led = Denko::LED.new(board: board, pin: PIN)

led.blink 0.5

sleep
