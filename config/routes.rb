Rails.application.routes.draw do
  get "sessions/new"
  get "sessions/create"
  get "sessions/destroy"
  root "home#index"
  get "home", to: "home#index", as: "home"
  resources :users
  resources :movies do
    collection do
      get "search", to: "movies#search"
    end
    post "store", on: :collection
    get "details", on: :collection
  end

  resources :sessions, only: [ :new, :create, :destroy ]
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  get "/logout", to: "sessions#destroy"

  resources :ratings, only: [ :create ]

  get "rated_movies", to: "movies#rated_movies"

  get "up" => "rails/health#show", as: :rails_health_check
end
