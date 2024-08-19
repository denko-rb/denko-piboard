require_relative 'lib/denko/piboard_version'

Gem::Specification.new do |s|
  s.name        = 'denko-piboard'
  s.version     = Denko::PiBoard::VERSION
  s.licenses    = ['MIT']
  s.summary     = "Use Raspberry Pi built-in GPIO as a Board class with the denko gem"
  s.description = "Denko::PiBoard is a drop-in replacement for Denko::Board. Use denko features and component classes to be used directly on a Raspberry Pi."

  s.authors     = ["vickash"]
  s.email       = 'mail@vickash.com'
  s.files       =  Dir['**/*'].reject { |f| f.match /.gem\z/}
  s.homepage    = 'https://github.com/denko-rb/denko-piboard'
  s.metadata    = { "source_code_uri" => "https://github.com/denko-rb/denko-piboard" }
  
  # libgpio C extension
  s.extensions = %w[ext/gpiod/extconf.rb]

  s.add_dependency 'pigpio', '~> 0.1.12'
  s.add_dependency 'denko',  '~> 0.13'
end
