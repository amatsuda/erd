require 'rubygems'
require 'bundler'

Bundler.require :default, :development

Combustion.initialize!

require 'rspec/rails'

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
