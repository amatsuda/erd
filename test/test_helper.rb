$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
# load Rails first
require 'rails'
require 'erd'
require 'fake_app/fake_app'
require 'test/unit/rails/test_help'
Bundler.require

ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths.map {|p| Rails.root.join p}, nil)
