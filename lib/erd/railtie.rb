# frozen_string_literal: true

require 'rails'
require 'erd/engine'

module Erd
  autoload :Migrator, 'erd/migrator'
  autoload :GenaratorRunner, 'erd/generator_runner'

  class Railtie < ::Rails::Railtie #:nodoc:
    initializer 'erd' do
      ActiveSupport.on_load(:after_initialize) do
        if Rails.env.development?
          Rails.application.routes.prepend do
            mount Erd::Engine, :at => '/erd'
          end
        end
      end
    end
  end
end
