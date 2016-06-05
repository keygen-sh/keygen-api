Rails.application.routes.draw do
  scope module: "api" do
    namespace :v1 do
      get  :token, to: "tokens#login"
      post :token, to: "tokens#reset"
      resources :products
      resources :users
      resources :policies
      resources :licenses
    end
  end
end
