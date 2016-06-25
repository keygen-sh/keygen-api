Rails.application.routes.draw do
  scope module: "api" do

    def json_request?(r)
      !(/json/ =~ r.content_type).nil?
    end

    namespace :v1, constraints: lambda { |r| json_request?(r) } do
      resources :stripe, only: [:create]

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

      constraints lambda { |r| r.subdomain.empty? } do
        resources :plans
        resources :accounts do
          namespace :relationships do
            relationship :plan, only: [:update]
          end
          namespace :actions do
            action :post, :activate, to: "activation#activate"
            action :post, :pause, to: "subscription#pause"
            action :post, :resume, to: "subscription#resume"
            action :post, :cancel, to: "subscription#cancel"
          end
        end
      end

      constraints lambda { |r| r.subdomain.present? } do
        get  :tokens, to: "tokens#login"
        post :tokens, to: "tokens#reset_tokens"
        post :passwords, to: "passwords#reset_password"
        get  :profile, to: "profiles#show"
        resources :users do
          namespace :actions do
            action :post, :update_password, to: "password#update_password"
            action :post, :reset_password, to: "password#reset_password"
          end
        end
        resources :policies do
          namespace :relationships do
            relationship :pool, only: [:create, :destroy]
          end
        end
        resources :licenses do
          namespace :relationships do
            relationship :machines, only: [:create, :destroy]
          end
          namespace :actions do
            action :get, :verify, to: "verify#verify_license"
            action :post, :revoke, to: "revoke#revoke_license"
            action :post, :renew, to: "renew#renew_license"
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

  constraints lambda { |r| r.subdomain.present? || json_request?(r) } do
    %w[404 422 500].each do |code|
      match code, to: "errors#show", code: code, via: :all
    end
    root to: "errors#show", code: 404
  end

  constraints lambda { |r| r.subdomain.empty? && !json_request?(r) } do
    match "*all", to: "application#index", via: [:get]
    root to: "application#index"
  end
end
