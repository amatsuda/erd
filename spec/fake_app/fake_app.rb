require 'active_record'
require 'action_controller/railtie'

# config
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

module ErdApp
  class Application < Rails::Application
    # Rais.root
    config.root = File.dirname(__FILE__)

    config.secret_token = 'fall to your knees and repent if you please'
    config.session_store :cookie_store, :key => '_myapp_session'
    config.active_support.deprecation = :log
    config.eager_load = false

    config.app_generators.orm :active_record, :migration => true, :timestamps => true
  end
end
ErdApp::Application.initialize!
ErdApp::Application.routes.draw {}

# models
class Author < ActiveRecord::Base
  has_many :books
end
class Book < ActiveRecord::Base
  belongs_to :author
end

# helpers
module ApplicationHelper; end
