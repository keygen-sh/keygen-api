Rails.application.routes.draw do
  resources :plans
  resources :accounts
  resources :users
  resources :policies
  resources :licenses
  namespace :api do
    namespace :v1 do
        end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
