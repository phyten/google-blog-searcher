# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'google/blog/searcher/version'

Gem::Specification.new do |spec|
  spec.name          = "google-blog-searcher"
  spec.version       = Google::Blog::Searcher::VERSION
  spec.authors       = ["phyten"]
  spec.email         = ["phyten.obr@gmail.com"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency 'activesupport', ['>= 3.0.0']
  spec.add_dependency 'actionpack', ['>= 3.0.0']
  spec.add_dependency 'moji'
  spec.add_dependency 'feed-normalizer'
  spec.add_dependency 'mechanize'
  spec.add_dependency 'scraper'

  spec.add_development_dependency 'bundler', ['>= 1.0.0']
  spec.add_development_dependency 'rake', ['>= 0']
  spec.add_development_dependency 'rspec', ['>= 0']
  spec.add_development_dependency 'rdoc', ['>= 0']
  spec.add_development_dependency 'pry'
  

end
