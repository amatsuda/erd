require 'test_helper'

feature 'erd#index' do
  scenario 'with author and book model' do
    visit '/erd'
    assert page.has_content? 'Author'
    assert page.has_content? 'name'
    assert page.has_content? 'Book'
    assert page.has_content? 'title'
  end
end
