Rails.application.routes.draw do
  scope module: "api" do
    rel = -> r1, r2 { "/api/v1/#{r1}/relationships/#{r2}" }
    act = -> r, a { "/api/v1/#{r}/actions/#{a}" }

    namespace :v1 do
      get  :token, to: "tokens#login"
      post :token, to: "tokens#reset"
      resources :accounts
      resources :users
      resources :policies
      resources :licenses
      resources :products do
        namespace :relationships do
          resources :users, controller: rel.call(:products, :users), only: [:create, :destroy]
        end
      end
    end
  end
end
