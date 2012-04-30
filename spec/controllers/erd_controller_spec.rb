require 'spec_helper'

describe Erd::ErdController do
  it 'should GET :index' do
    get :index

    response.should render_template('index')
  end
end

