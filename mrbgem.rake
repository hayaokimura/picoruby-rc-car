MRuby::Gem::Specification.new('picoruby-rc-car') do |spec|
  spec.license = 'MIT'
  spec.author  = 'hayaokimura'
  spec.summary = 'RC Car controller for PicoRuby'

  spec.add_dependency 'picoruby-ble-uart'
end
