# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RAILS_ENV'] = 'development'

# load Rails first
require 'rails'
require 'action_controller/railtie'
require 'active_record/railtie'
require 'erd'
require 'fake_app/fake_app'
require 'test/unit/rails/test_help'
Bundler.require
require 'capybara'
require 'selenium/webdriver'

begin
  require "action_dispatch/system_test_case"
rescue LoadError
  Capybara.register_driver :chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new(:args => %w[no-sandbox headless disable-gpu])
    Capybara::Selenium::Driver.new(app, :browser => :chrome, :options => options)
  end
  Capybara.javascript_driver = :chrome
else
  ActionDispatch::SystemTestCase.driven_by(:selenium, :using => :headless_chrome)
end

ActiveRecord::Migration.verbose = false
if defined? ActiveRecord::MigrationContext  # >= 5.2
  ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
  ActiveRecord::Base.connection.migration_context.migrate
else
  ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths.map {|p| Rails.root.join p}, nil)
end
