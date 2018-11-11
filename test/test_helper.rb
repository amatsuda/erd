$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

ENV['RAILS_ENV'] = 'development'

# load Rails first
require 'rails'
require 'jquery-rails'
require 'erd'
require 'fake_app/fake_app'
require 'test/unit/rails/test_help'
Bundler.require

ActiveRecord::Migration.verbose = false
if defined? ActiveRecord::MigrationContext  # >= 5.2
  ActiveRecord::Migrator.migrations_paths = Rails.application.paths['db/migrate'].to_a
  ActiveRecord::Base.connection.migration_context.migrate
else
  ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths.map {|p| Rails.root.join p}, nil)
end
