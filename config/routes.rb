Rails.application.routes.draw do
  scope module: "api" do
    namespace :v1 do

      def relationship(resource, opts = {})
        resources(resource.to_s.dasherize, {
          controller: "/api/v1/#{parent_resource.name}/relationships/#{resource}"
        }.merge(opts))
      end

      def action(verb, action, opts = {})
        send(verb, action.to_s.dasherize, {
          controller: "/api/v1/#{parent_resource.name}/actions/actions",
          to: "/api/v1/#{parent_resource.name}/actions/#{opts[:to]}"
        })
      end

      get  :tokens, to: "tokens#login"
      post :tokens, to: "tokens#reset_tokens"

      post :passwords, to: "passwords#reset_password"

      resources :accounts do

        namespace :relationships do
          relationship :plans, only: [:create]
        end

        namespace :actions do
          action :post, :pause, to: "status#pause"
          action :post, :resume, to: "status#resume"
          action :post, :cancel, to: "status#cancel"
        end
      end

      resources :users do

        namespace :actions do
          action :post, :update_password, to: "password#update_password"
          action :post, :reset_password, to: "password#reset_password"
        end
      end

      resources :policies do
      end

      resources :licenses do

        namespace :relationships do
          relationship :machines, only: [:create, :destroy]
        end

        namespace :actions do
          action :get, :verify, to: "verify#verify"
        end
      end

      resources :products do |r|

        namespace :relationships do
          relationship :users, only: [:create, :destroy]
        end
      end
    end
  end
end
