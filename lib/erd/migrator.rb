# frozen_string_literal: true

require 'rails/generators'

module Erd
  class MigrationError < StandardError; end

  class Migrator
    class << self
      def status
        migrations = []
        migration_table_name = find_schema_migration_table_name
        return migrations unless ActiveRecord::Base.connection.table_exists? migration_table_name

        migrated_versions = ActiveRecord::Base.connection.select_values("SELECT version FROM #{migration_table_name}").map {|v| '%.3d' % v}
        ActiveRecord::Migrator.migrations_paths.each do |path|
          Dir.foreach(Rails.root.join(path)) do |file|
            if (version_and_name = /^(\d{3,})_(.+)\.rb$/.match(file))
              status = migrated_versions.delete(version_and_name[1]) ? 'up' : 'down'
              migrations << {:status => status, :version => version_and_name[1], :name => version_and_name[2], :filename => file}
            end
          end
        end
        migrations += migrated_versions.map {|v| {:status => 'up', :version => v, :name => '*** NO FILE ***', :filename => v}}
        migrations.sort_by {|m| m[:version]}
      end

      # `rake db:migrate`
      # example:
      #   run_migrations up: '/Users/a_matsuda/my_app/db/migrate/20120423023323_create_products.rb'
      #   run_migrations up: '20120512020202', down: ...
      #   run_migrations up: ['20120512020202', '20120609010203', ...]
      def run_migrations(migrations)
        migrations.each do |direction, version_or_filenames|
          Array.wrap(version_or_filenames).each do |version_or_filename|
            version = File.basename(version_or_filename)[/\d{3,}/]

            if defined? ActiveRecord::MigrationContext  # >= 5.2
              ActiveRecord::Base.connection.migration_context.run(direction, version.to_i)
            else
              ActiveRecord::Migrator.run(direction, ActiveRecord::Migrator.migrations_paths, version.to_i)
            end
          end if version_or_filenames
        end
        if ActiveRecord::Base.schema_format == :ruby
          File.open(ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb", 'w') do |file|
            ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          end
        end
        #TODO unload migraion classes
      end

      private

      def find_schema_migration_table_name
        return ActiveRecord::Migrator.schema_migrations_table_name unless defined?(ActiveRecord::SchemaMigration)
        return ActiveRecord::SchemaMigration.table_name if ActiveRecord::SchemaMigration.respond_to?(:table_name)

        ActiveRecord::Base.connection.schema_migration.table_name
      end
    end
  end
end
