Rails.application.routes.draw do
  scope module: 'api' do
    namespace :v1 do
      resources :plans
      resources :accounts
      resources :products
      resources :users
      resources :policies
      resources :licenses
    end
  end
end
