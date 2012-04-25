Erd::Engine.routes.draw do
  get '/' => 'erd#index'
  put '/' => 'erd#update'
  root :to => 'erd#index'
end
