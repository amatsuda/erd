require 'rails/generators'
require 'nokogiri'
require 'rails_erd/diagram/graphviz'
require 'pp'

class ErdController < ApplicationController
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
    render_to_string 'erd/erd', :layout => nil, :locals => {:width => BigDecimal(svg_width) * ratio, :height => BigDecimal(svg_height) * ratio, :models => models, :edges => edges}
  end
end
