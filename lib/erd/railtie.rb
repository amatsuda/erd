require 'rails'
require 'erd/engine'


module Erd
  autoload :Migrator, 'erd/migrator'

  class Railtie < ::Rails::Railtie #:nodoc:
    config.to_prepare do
      if Rails.env.development?
        Rails.application.routes.append do
          mount Erd::Engine, :at => '/erd'
        end
      end
    end
  end
end
