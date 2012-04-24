Game::Application.routes.draw do

  devise_for :users

  resources :game, :only => :index

  resources :users, :only => [ :show ]

  resources :jobs, :only => [ :index ] do
    member do
      get 'accept'
    end
  end

  resources :actions, :only => [:index, :show, :create, :destroy] do
    collection do
      get 'current'
      get 'recent'
    end
  end

  root :to => 'game#index'
  match "/" => 'game#index'
end