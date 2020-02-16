
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "activecube/version"

Gem::Specification.new do |spec|
  spec.name          = "activecube"
  spec.version       = Activecube::VERSION
  spec.authors       = ["Aleksey Studnev"]
  spec.email         = ["astudnev@gmail.com"]

  spec.summary       = %q{Multi-Dimensional Queries with Rails}
  spec.description   = %q{Activecube is the library to make multi-dimensional queries to data.Cube, dimensions, metrics and selectors are defined in the Model, similary to ActiveRecord.
Activecube uses Rails ActiveRecord in implementation. In particular, you have to define all tables, used in Activecube, as ActiveRecord tables.}
  spec.homepage      = "https://github.com/bitquery/activecube"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord', '>= 5.2'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
