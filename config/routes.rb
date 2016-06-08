Rails.application.routes.draw do
  scope module: "api" do
    namespace :v1 do

      def relationship(resource, opts = {})
        resources(resource, {
          controller: "/api/v1/#{parent_resource.name}/relationships/#{resource}"
        }.merge(opts))
      end

      def action(verb, action, opts = {})
        send(verb, action, {
          controller: "/api/v1/#{parent_resource.name}/actions/actions",
          to: "/api/v1/#{parent_resource.name}/actions/#{opts[:to]}"
        })
      end

      get  :tokens, to: "tokens#login"
      post :tokens, to: "tokens#reset"

      post :passwords, to: "passwords#reset"

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
