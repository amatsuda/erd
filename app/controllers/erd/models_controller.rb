module Erd
  class ModelsController < ::Erd::ApplicationController
    # doesn't actually create anything. Just draw the given model
    def create
      model = {:model => params[:model_name], :x => 300, :y => 100, :width => 300, :height => 300, :columns => params[:columns]}
      <%= render :partial => 'erd/erd/model', :object => model -%>
    end
  end
end
