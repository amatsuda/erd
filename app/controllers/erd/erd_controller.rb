# frozen_string_literal: true

require 'nokogiri'
require 'ruby-graphviz'
require 'erd/application_controller'

module Erd
  class ErdController < ::Erd::ApplicationController
    def index
      redirect_to :edit
    end

    def edit
      plain = generate_plain
      positions = if (json = Rails.root.join('tmp/erd_positions.json')).exist?
        ActiveSupport::JSON.decode json.read
      else
        {}
      end
      @erd = render_plain plain, positions

      @migrations = Erd::Migrator.status
    end

    def update
      changes = params[:changes].present? ? ActiveSupport::JSON.decode(params[:changes]) : []
      executed_migrations, failed_migrations = [], []
      changes.each do |row|
        begin
          action, model, column, from, to = row['action'], row['model'], row['column'], row['from'], row['to']
          if action == 'move'
            model = model.tableize
            json_file = Rails.root.join('tmp', 'erd_positions.json')
            positions = json_file.exist? ? ActiveSupport::JSON.decode(json_file.read) : {}
            positions[model] = to
            json_file.open('w') {|f| f.write positions.to_json}
          else
            case action
            when 'create_model'
              columns = column.split(' ').compact
              generated_migration_file = Erd::GenaratorRunner.execute_generate_model model, columns
            when 'remove_model'
              model = model.tableize
              generated_migration_file = Erd::GenaratorRunner.execute_generate_migration "drop_#{model}"
              gsub_file generated_migration_file, /def (up|change).*  end/m, "def change\n    drop_table :#{model}\n  end"
            when 'rename_model'
              _model, from, to = from.tableize, to.tableize, model.tableize
              generated_migration_file = Erd::GenaratorRunner.execute_generate_migration "rename_#{from}_to_#{to}"
              gsub_file generated_migration_file, /def (up|change).*  end/m, "def change\n    rename_table :#{from}, :#{to}\n  end"
            when 'add_column'
              model = model.tableize
              name_and_type = column.scan(/(.*)\((.*?)\)/).first
              name, type = name_and_type[0], name_and_type[1]
              generated_migration_file = Erd::GenaratorRunner.execute_generate_migration "add_#{name}_to_#{model}", ["#{name}:#{type}"]
            when 'rename_column'
              model = model.tableize
              generated_migration_file = Erd::GenaratorRunner.execute_generate_migration "rename_#{model}_#{from}_to_#{to}"
              gsub_file generated_migration_file, /def (up|change).*  end/m, "def change\n    rename_column :#{model}, :#{from}, :#{to}\n  end"
            when 'alter_column'
              model = model.tableize
              generated_migration_file = Erd::GenaratorRunner.execute_generate_migration "change_#{model}_#{column}_type_to_#{to}"
              gsub_file generated_migration_file, /def (up|change).*  end/m, "def change\n    change_column :#{model}, :#{column}, :#{to}\n  end"
            else
              raise "unexpected action: #{action}"
            end
            Erd::Migrator.run_migrations :up => generated_migration_file
            executed_migrations << generated_migration_file
          end
        rescue ::Erd::MigrationError => e
          failed_migrations << e.message
        end
      end

      redirect_to erd.root_path, :flash => {:executed_migrations => {:up => executed_migrations}, :failed_migrations => failed_migrations}
    end

    def migrate
      Erd::Migrator.run_migrations :up => params[:up], :down => params[:down]
      redirect_to erd.root_path, :flash => {:executed_migrations => params.slice(:up, :down)}
    end

    private

    def generate_plain
      if Rails.respond_to?(:autoloaders) && Rails.autoloaders.try(:zeitwerk_enabled?)
        Zeitwerk::Loader.eager_load_all
      else
        Rails.application.eager_load!
      end
      ar_descendants = ActiveRecord::Base.descendants.reject {|m| m.name.in?(%w(ActiveRecord::SchemaMigration ActiveRecord::InternalMetadata ApplicationRecord)) }
      ar_descendants.reject! {|m| !m.table_exists? }

      g = GraphViz.new('ERD', :type => :digraph, :rankdir => 'LR', :labelloc => :t, :ranksep => '1.5', :nodesep => '1.8', :margin => '0,0', :splines => 'spline') {|g|
        nodes = ar_descendants.each_with_object({}) do |model, hash|
          next if model.name.start_with? 'HABTM_'
          hash[model.name] = model.columns.reject {|c| c.name.in? %w(id created_at updated_at) }.map {|c| [c.name, c.type]}
        end

        edges = []
        ar_descendants.each do |model|
          model.reflect_on_all_associations.each do |reflection|
            next unless nodes.key? model.name
            next if reflection.macro == :belongs_to
            next unless nodes.key?(reflection.klass.name)

            edges << [model.name, reflection.klass.name]
            # don't include the FKs in the diagram
            nodes[reflection.klass.name].delete_if {|col, _type| col == reflection.foreign_key }
          end
        end

        nodes.each_pair do |model_name, cols|
          g.add_nodes model_name, 'shape' => 'record', 'label' => "#{model_name}|#{cols.map {|name, type| "#{name}(#{type})"}.join('\l')}"
        end
        edges.each do |from, to|
          g.add_edge g.search_node(from), g.search_node(to)
        end
      }
      g.output('plain' => String)
    end

    def render_plain(plain, positions)
      _scale, svg_width, svg_height = plain.scan(/\Agraph ([\d\.]+) ([\d\.]+) ([\d\.]+)$/).first
      # node name x y width height label style shape color fillcolor
      max_model_x, max_model_y = 0, 0
      models = plain.scan(/^node ([^ ]+) ([\d\.]+) ([\d\.]+) ([\d\.]+) ([\d\.]+) ([^ ]+) [^ ]+ [^ ]+ [^ ]+ [^ ]+\n/m).map {|model_name, x, y, width, height, label|
        columns = label.gsub("\\\n", '').split('|')[1].split('\l').map {|name_and_type| name_and_type.scan(/(.*?)\((.*?)\)/).first }.map {|n, t| {:name => n, :type => t} }
        custom_x, custom_y = positions[model_name.tableize].try(:split, ',')
        h = {:model => model_name, :x => (custom_x || (BigDecimal(x) * 72).round), :y => (custom_y || (BigDecimal(y) * 72).round), :width => (BigDecimal(width) * 72).round, :height => height, :columns => columns}
        max_model_x, max_model_y = [h[:x].to_i + h[:width].to_i, max_model_x, 1024].max, [h[:y].to_i + h[:height].to_i, max_model_y, 768].max
        h
      }.compact
      # edge tail head n x1 y1 .. xn yn [label xl yl] style color
      edges = plain.scan(/^edge ([^ ]+)+ ([^ ]+)/).map {|from, to| {:from => from, :to => to}}
      render_to_string 'erd/erd/erd', :layout => nil, :locals => {:width => [(BigDecimal(svg_width) * 72).round, max_model_x].max, :height => [(BigDecimal(svg_height) * 72).round, max_model_y].max, :models => models, :edges => edges}
    end

    def gsub_file(path, flag, *args, &block)
      path = File.expand_path path, Rails.root

      content = File.read path
      content.gsub! flag, *args, &block
      File.open(path, 'w') {|file| file.write content}
    end
  end
end
