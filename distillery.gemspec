# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "distillery/version"

Gem::Specification.new do |s|
  s.name        = "distillery"
  s.version     = Distillery::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jeff Pollard"]
  s.email       = ["jeff.pollard@gmail.com"]
  s.homepage    = "https://github.com/Fluxx/distillery"
  s.summary     = %q{Extract the content portion of an HTML document.}
  s.description = %q{Distillery extracts the "content" portion out of an HTML document. It applies heuristics based on element type, location, class/id name and other attributes to try and find the content part of the HTML document and return it.}

  s.rubyforge_project = "distillery"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency('nokogiri', '> 1.0')
  s.add_dependency('slop', '> 1.0')
  
  s.add_development_dependency('rspec', '> 2.0')
  s.add_development_dependency('guard')
  s.add_development_dependency('guard-rspec')
  s.add_development_dependency('ruby-debug19')
  s.add_development_dependency('rb-fsevent')
  s.add_development_dependency('growl')
end
