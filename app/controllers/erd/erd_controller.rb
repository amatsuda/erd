require 'rails/generators'
require 'nokogiri'
require 'rails_erd/diagram/graphviz'
require 'erd/application_controller'

module Erd
  class ErdController < ::Erd::ApplicationController
    def index
  #     `bundle exec rake erd filename=tmp/erd filetype=plain`
      Rails.application.eager_load!
      RailsERD.options[:filename], RailsERD.options[:filetype] = 'tmp/erd', 'plain'
      RailsERD::Diagram::Graphviz.create
      plain = Rails.root.join('tmp/erd.plain').read
      positions = if (json = Rails.root.join('tmp/erd_positions.json')).exist?
        ActiveSupport::JSON.decode json.read
      else
        {}
      end
      @erd = render_plain plain, positions
    end

    def update
      changes = ActiveSupport::JSON.decode(params[:changes])
      generated_migrations = []
      changes.each do |row|
        action, model, column, from, to = row['action'], row['model'].tableize, row['column'], row['from'], row['to']
        before_migration_files = Dir.glob Rails.root.join('db', 'migrate', '*.rb')
        case action
        when 'remove_model'
          execute_generate_migration "drop_#{model}"
          generated_migration_file = (Dir.glob(Rails.root.join('db', 'migrate', '*.rb')) - before_migration_files).first
          gsub_file generated_migration_file, /def up.*  end/m, "def change\n    drop_table :#{model}\n  end"
          generated_migrations << File.basename(generated_migration_file)
        when 'rename_model'
          from, to = from.tableize, to.tableize
          execute_generate_migration "rename_#{from}_to_#{to}"
          generated_migration_file = (Dir.glob(Rails.root.join('db', 'migrate', '*.rb')) - before_migration_files).first
          gsub_file generated_migration_file, /def up.*  end/m, "def change\n    rename_table :#{from}, :#{to}\n  end"
          generated_migrations << File.basename(generated_migration_file)
        when 'add_column'
          name_and_type = column.scan(/(.*)\((.*?)\)/).first
          name, type = name_and_type[0], name_and_type[1]
          execute_generate_migration "add_#{name}_to_#{model}", ["#{name}:#{type}"]
          generated_migration_file = (Dir.glob(Rails.root.join('db', 'migrate', '*.rb')) - before_migration_files).first
          generated_migrations << File.basename(generated_migration_file)
        when 'rename_column'
          execute_generate_migration "rename_#{model}_#{from}_to_#{to}"
          generated_migration_file = (Dir.glob(Rails.root.join('db', 'migrate', '*.rb')) - before_migration_files).first
          gsub_file generated_migration_file, /def up.*  end/m, "def change\n    rename_column :#{model}, :#{from}, :#{to}\n  end"
          generated_migrations << File.basename(generated_migration_file)
        when 'alter_column'
          execute_generate_migration "change_#{model}_#{column}_type_to_#{to}"
          generated_migration_file = (Dir.glob(Rails.root.join('db', 'migrate', '*.rb')) - before_migration_files).first
          gsub_file generated_migration_file, /def up.*  end/m, "def change\n    change_column :#{model}, :#{column}, :#{to}\n  end"
          generated_migrations << File.basename(generated_migration_file)
        when 'move'
          json_file = Rails.root.join('tmp', 'erd_positions.json')
          positions = json_file.exist? ? ActiveSupport::JSON.decode(json_file.read) : {}
          positions[model] = to
          json_file.open('w') {|f| f.write positions.to_json}
          generated_migrations << 'saved entity positions'
        else
          raise "unexpected action: #{action}"
        end
      end

      flash[:generated_migrations] = generated_migrations
      redirect_to erd.root_path
    end

    private
    def render_plain(plain, positions)
      _scale, svg_width, svg_height = plain.scan(/\Agraph ([0-9\.]+) ([0-9\.]+) ([0-9\.]+)$/).first
      ratio = [BigDecimal('4800') / BigDecimal(svg_width), BigDecimal('3200') / BigDecimal(svg_height), 180].min
      # node name x y width height label style shape color fillcolor
      models = plain.scan(/^node ([^ ]+) ([0-9\.]+) ([0-9\.]+) ([0-9\.]+) ([0-9\.]+) <\{?(<((?!^\}?>).)*)^\}?> [^ ]+ [^ ]+ [^ ]+ [^ ]+\n/m).map {|node_name, x, y, width, height, label|
        label_doc = Nokogiri::HTML::DocumentFragment.parse(label)
        model_name = label_doc.search('table')[0].search('tr > td').first.text
        next if model_name == 'ActiveRecord::SchemaMigration'
        columns = []
        if (cols_table = label_doc.search('table')[1])
          columns = cols_table.search('tr > td').map {|col| col_name, col_type = col.text.split(' '); {:name => col_name, :type => col_type}}
        end
        custom_x, custom_y = positions[model_name.tableize].try(:split, ',')
        {:model => model_name, :name => node_name, :x => (custom_x || BigDecimal(x) * ratio), :y => (custom_y || BigDecimal(y) * ratio), :width => BigDecimal(width) * ratio, :height => height, :columns => columns}
      }.compact
      # edge tail head n x1 y1 .. xn yn [label xl yl] style color
      edges = plain.scan(/^edge ([^ ]+)+ ([^ ]+)/).map {|from, to| {:from => from, :to => to}}
      render_to_string 'erd/erd/erd', :layout => nil, :locals => {:width => BigDecimal(svg_width) * ratio, :height => BigDecimal(svg_height) * ratio, :models => models, :edges => edges}
    end

    def execute_generate_migration(name, options = nil)
      overwriting_argv([name, options]) do
        Rails::Generators.configure! Rails.application.config.generators
        Rails::Generators.invoke 'migration', [name, options], :behavior => :invoke, :destination_root => Rails.root
      end
    end

    # `rake db:migrate`
    def migrate
      ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_path, ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
      if ActiveRecord::Base.schema_format == :ruby
        File.open(ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb", "w") do |file|
          ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
        end
      end
    end

    # a dirty workaround to make rspec-rails run
    def overwriting_argv(value, &block)
      original_argv = ARGV
      Object.const_set :ARGV, value
      block.call
    ensure
      Object.const_set :ARGV, original_argv
    end

    def gsub_file(path, flag, *args, &block)
      path = File.expand_path path, Rails.root

      content = File.read path
      content.gsub! flag, *args, &block
      File.open(path, 'w') {|file| file.write content}
    end
  end
end
