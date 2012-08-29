require File.expand_path("lib/wineskins/version", File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name        = "wineskins"
  s.version     = Wineskins::VERSION
  s.authors     = ["Eric Gjertsen"]
  s.email       = ["ericgj72@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Simple database transfer utility using Sequel}
  s.description = %q{Simple database transfer utility using Sequel}

  s.rubyforge_project = ""

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'sequel', '~> 3.0'
end