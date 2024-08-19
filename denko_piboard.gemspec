require_relative 'lib/denko/piboard_version'

Gem::Specification.new do |s|
  s.name        = 'denko-piboard'
  s.version     = Denko::PiBoard::VERSION
  s.licenses    = ['MIT']
  s.summary     = "Use single board computer GPIO as a Board class with the denko gem"
  s.description = "Denko::PiBoard is a drop-in replacement for Denko::Board. Use denko with peripherals connected directly to a SBC"

  s.authors     = ["vickash"]
  s.email       = 'mail@vickash.com'
  s.files       =  Dir['**/*'].reject { |f| f.match /.gem\z/}
  s.homepage    = 'https://github.com/denko-rb/denko-piboard'
  s.metadata    = { "source_code_uri" => "https://github.com/denko-rb/denko-piboard" }
  
  s.add_dependency 'lgpio',  '~> 0.1'
  s.add_dependency 'denko',  '~> 0.14'
end
