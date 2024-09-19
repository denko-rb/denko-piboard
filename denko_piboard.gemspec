require_relative 'lib/denko/piboard_version'

Gem::Specification.new do |s|
  s.name        = 'denko-piboard'
  s.version     = Denko::PiBoard::VERSION
  s.licenses    = ['MIT']
  s.summary     = "Use Linux GPIO, I2C, SPI and PWM as a Denko::PiBoard"
  s.description = "Use Linux GPIO, I2C, SPI and PWM as a Denko::PiBoard"

  s.authors     = ["vickash"]
  s.email       = 'mail@vickash.com'
  s.files       =  Dir['**/*'].reject { |f| f.match /.gem\z/}
  s.homepage    = 'https://github.com/denko-rb/denko-piboard'
  s.metadata    = { "source_code_uri" => "https://github.com/denko-rb/denko-piboard" }

  s.add_dependency 'lgpio',  '~> 0.1'
  s.add_dependency 'denko',  '~> 0.14'
end
