Rails.application.routes.draw do
  namespace :v1 do
    resources :plans
    resources :accounts
    resources :users
    resources :policies
    resources :licenses
  end
end
