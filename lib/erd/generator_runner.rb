require 'rails/generators'

module Erd
  class GenaratorRunner
    class << self
      # runs `rails g model [name]`
      # @return generated migration filename
      def execute_generate_model(name, options = nil)
        result = execute_generator 'model', name, options
        result.flatten.grep(%r(/db/migrate/.*\.rb))
      end

      # runs `rails g migration [name]`
      # @return generated migration filename
      def execute_generate_migration(name, options = nil)
        result = execute_generator 'migration', name, options
        result.last.last
      end

      private
      # a dirty workaround to make rspec-rails run
      def overwriting_argv(value, &block)
        original_argv = ARGV
        Object.const_set :ARGV, value
        block.call
      ensure
        Object.const_set :ARGV, original_argv
      end

      def execute_generator(type, name, options = nil)
        overwriting_argv([name, options]) do
          Rails::Generators.configure! Rails.application.config.generators
          result = Rails::Generators.invoke type, [name, options], :behavior => :invoke, :destination_root => Rails.root
          raise ::Erd::MigrationError, "#{name}#{"(#{options})" if options}" unless result
          result
        end
      end
    end
  end
end
