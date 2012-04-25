# -*- encoding: utf-8 -*-
require File.expand_path('../lib/erd/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Akira Matsuda"]
  gem.email         = ["ronnie@dio.jp"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "erd"
  gem.require_paths = ["lib"]
  gem.version       = Erd::VERSION

  gem.add_runtime_dependency 'rails-erd', ['>= 0.4.5']
  gem.add_runtime_dependency 'nokogiri'
end
