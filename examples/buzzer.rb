#
# Example of playing a melody on a piezoelectric buzzer.
#
require 'denko/piboard'

PIN = 268
board = Denko::PiBoard.new
buzzer = Denko::PulseIO::Buzzer.new(board: board, pin: PIN)

C4 = 262
D4 = 294
E4 = 330

notes = [
        [E4, 1], [D4, 1], [C4, 1], [D4, 1], [E4, 1], [E4, 1], [E4, 2],
        [D4, 1], [D4, 1], [D4, 2],          [E4, 1], [E4, 1], [E4, 2],
        [E4, 1], [D4, 1], [C4, 1], [D4, 1], [E4, 1], [E4, 1], [E4, 1], [E4, 1],
        [D4, 1], [D4, 1], [E4, 1], [D4, 1], [C4, 4],
        ]

bpm = 240
beat_time = 60.to_f / bpm

notes.each do |note|
  buzzer.tone(note[0], (note[1] * beat_time))
end

# Only works for PiBoard.
sleep 0.100 while (board.tone_busy(PIN) == 1)

buzzer.stop
board.finish_write
