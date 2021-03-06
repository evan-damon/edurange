# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'edurange/version'

Gem::Specification.new do |gem|
  gem.name          = "edurange"
  gem.version       = Edurange::VERSION
  gem.authors       = ["Stefan Boesen"]
  gem.email         = ["stefan.boesen@gmail.com"]
  gem.description   = %q{EDURange Project}
  gem.summary       = %q{Automatic warspace simulations}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_runtime_dependency "aws-sdk"
  gem.add_runtime_dependency "pry"
end
