# frozen_string_literal: true

module Erd
  class Engine < ::Rails::Engine
    isolate_namespace Erd

    initializer 'erd engine' do |app|
      if Rails.env.development?
        app.middleware.insert_before ::ActionDispatch::Static, ::ActionDispatch::Static, root.join('public').to_s
      end
    end
  end
end
