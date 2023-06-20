require_relative 'lib/denko/piboard_version'

Gem::Specification.new do |s|
  s.name        = 'denko-piboard'
  s.version     = Denko::PiBoard::VERSION
  s.licenses    = ['MIT']
  s.summary     = "Use a Raspberry Pi's built-in GPIO as a board with the denko gem"
  s.description = "Denko::PiBoard plugs in as a (mostly) seamless replacement for Denko::Board. This allows denko features and component classes to be used directly on a Raspberry Pi, without an external microcontroller."

  s.authors     = ["vickash"]
  s.email       = 'mail@vickash.com'
  s.files       =  Dir['**/*'].reject { |f| f.match /.gem\z/}
  s.homepage    = 'https://github.com/denko-rb/denko-piboard'
  s.metadata    = { "source_code_uri" => "https://github.com/denko-rb/denko-piboard" }
  
  # libgpio C extension
  s.extensions = %w[ext/gpiod/extconf.rb]

  s.add_dependency 'pigpio'
  s.add_dependency 'denko'
end
