require 'test_helper'

class ErdIndexTest < ActionDispatch::IntegrationTest
  test 'with author and book model' do
    visit '/erd'
    assert has_content? 'Author', minimum: 1
    assert has_content? 'name'
    assert has_content? 'Book'
    assert has_content? 'title'
  end
end
