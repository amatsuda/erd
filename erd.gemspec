# -*- encoding: utf-8 -*-
require File.expand_path('../lib/erd/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Akira Matsuda']
  gem.email         = ['ronnie@dio.jp']
  gem.description   = 'erd engine on Rails'
  gem.summary       = 'erd engine on Rails'
  gem.homepage      = 'https://github.com/amatsuda/erd'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'erd'
  gem.require_paths = ['lib']
  gem.version       = Erd::VERSION

  gem.add_runtime_dependency 'rails-erd', ['>= 0.4.5']
  gem.add_runtime_dependency 'nokogiri'

  gem.add_development_dependency 'rails', '>= 3.2'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'test-unit-rails'
  gem.add_development_dependency 'capybara', '>= 2'
  gem.add_development_dependency 'rr'
  gem.add_development_dependency 'sqlite3'
end
