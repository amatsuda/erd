require 'spec_helper'

feature 'erd#index' do
  scenario 'with author and book model' do
    visit '/erd'
    page.should have_content 'Author'
    page.should have_content 'name'
    page.should have_content 'Book'
    page.should have_content 'title'
  end
end
