Erd::Engine.routes.draw do
  get '/' => 'erd#index'
  put '/' => 'erd#update'
  put '/migrate' => 'erd#migrate', :as => 'migrate'
  root :to => 'erd#index'
end
