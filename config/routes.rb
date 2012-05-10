Game::Application.routes.draw do
  scope "/game" do
    devise_for :users

    resources :game, :only => :index

    resources :users, :only => [ :show, :index ] do
      collection do
        get :stats
      end
    end

    resources :notifications, :only => [ :index ] do
      collection do
        put :read
      end
    end

    resources :equipments, :only => [ :index, :update ] do
      collection do
        post :buy
      end
    end

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

    match 'operations' => 'actions#operations', :as => :operations

    root :to => 'game#index'
    match "/" => 'game#index'
  end

  root :to => 'game#index'
end