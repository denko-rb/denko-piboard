require_relative 'lib/dino/piboard_version'

Gem::Specification.new do |s|
  s.name        = 'dino-piboard'
  s.version     = Dino::PiBoard::VERSION
  s.licenses    = ['MIT']
  s.summary     = "Use a Raspberry Pi's built-in GPIO as a board with the dino gem"
  s.description = "Dino::PiBoard plugs in as a (mostly) seamless replacement for Dino::Board. This allows dino features and component classes to be used directly on a Raspberry Pi, without needing an external microcontroller."

  s.authors     = ["vickash"]
  s.email       = 'vickashmahabir@gmail.com'
  s.files       =  Dir['**/*']
  s.homepage    = 'https://github.com/dino-rb/dino-piboard'
  s.metadata    = { "source_code_uri" => "https://github.com/dino-rb/dino-piboard" }

  s.add_dependency 'pigpio_ffi'
  s.add_dependency 'dino'
end
