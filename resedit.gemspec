lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'resedit'
  s.version     = "1.8.6"
  s.summary     = "OG resource proc library!"
  s.authors     = ["bjfn"]
  s.files       = Dir['lib/**/*.rb']
  s.executables   = ["resedit"]
  s.add_dependency "chunky_png", "~>1.3"
  s.add_dependency "builder", "~> 3.2"
#  s.add_dependency "free-image", "~> 0.8"
  s.required_ruby_version = '~> 2.1'
end