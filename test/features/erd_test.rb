# frozen_string_literal: true

require 'test_helper'

class ErdIndexTest < ActionDispatch::IntegrationTest
  test 'with author and book model' do
    visit '/erd'

    if Capybara::VERSION > '3'
      assert has_content? 'Author', :minimum => 1
    else
      assert has_content? 'Author'
    end
    assert has_content? 'name'
    assert has_content? 'Book'
    assert has_content? 'title'
  end
end
