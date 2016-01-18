lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resedit'

Gem::Specification.new do |s|
  s.name        = 'Resedit'
  s.version     = Resedit::VERSION
  s.summary     = "OG resource proc library!"
  s.authors     = ["bjfn"]
  s.files       = Dir['lib/**/*.rb']
end