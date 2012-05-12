$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
# load Rails first
require 'rails'
require 'erd'
# needs to load the app before loading rspec/rails => capybara
require 'fake_app/fake_app'
require 'rspec/rails'
# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rr
  config.before :all do
    ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths.map {|p| Rails.root.join p}, nil)
  end
end
