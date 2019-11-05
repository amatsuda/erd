# frozen_string_literal: true

module Erd
  class Engine < ::Rails::Engine
    isolate_namespace Erd

    initializer 'erd' do |app|
      if Rails.env.development?
        ActiveSupport.on_load :after_initialize do
          Rails.application.routes.prepend do
            mount Erd::Engine, :at => '/erd'
          end
        end

        app.middleware.insert_before ::ActionDispatch::Static, ::ActionDispatch::Static, root.join('public').to_s
      end
    end
  end
end
