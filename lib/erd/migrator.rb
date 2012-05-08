require 'rails/generators'

module Erd
  class MigrationError < StandardError; end

  class Migrator
    class << self
      def status
        migrated_versions = ActiveRecord::Base.connection.select_values("SELECT version FROM #{ActiveRecord::Migrator.schema_migrations_table_name}").map {|v| '%.3d' % v}
        migrations = []
        ActiveRecord::Migrator.migrations_paths.each do |path|
          Dir.foreach(Rails.root.join(path)) do |file|
            if (version_and_name = /^(\d{3,})_(.+)\.rb$/.match(file))
              status = migrated_versions.delete(version_and_name[1]) ? 'up' : 'down'
              migrations << {:status => status, :version => version_and_name[1], :name => version_and_name[2]}
            end
          end
        end
        migrations += migrated_versions.map {|v| {:status => 'up', :version => v, :name => '*** NO FILE ***'}}
        migrations.sort_by {|m| m[:version]}
      end

      # `rake db:migrate`
      def run_migrations(migrations)
        migrations.each do |direction, versions|
          versions.each do |version|
            ActiveRecord::Migrator.run(direction, ActiveRecord::Migrator.migrations_path, version.to_i)
          end if versions
        end
        if ActiveRecord::Base.schema_format == :ruby
          File.open(ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb", 'w') do |file|
            ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          end
        end
        #TODO unload migraion classes
      end

      def execute_generate_migration(name, options = nil)
        overwriting_argv([name, options]) do
          Rails::Generators.configure! Rails.application.config.generators
          result = Rails::Generators.invoke 'migration', [name, options], :behavior => :invoke, :destination_root => Rails.root
          raise ::Erd::MigrationError, "#{name}#{"(#{options})" if options}" unless result
        end
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
    end
  end
end
