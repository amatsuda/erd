# frozen_string_literal: true

Erd::Engine.routes.draw do
  get '/' => 'erd#index'
  get 'edit' => 'erd#edit'
  put '/' => 'erd#update'
  put '/migrate' => 'erd#migrate', :as => 'migrate'
  root :to => 'erd#index'
end
