require_dependency Rails.root.join "lib/routes_helper"

Rails.application.routes.draw do
  scope module: "api" do
    namespace :v1, constraints: { format: "json" } do

      constraints lambda { |r| r.subdomain.empty? } do
        resource :stripe, only: [:create]
        resource :plans
        resource :accounts do
          namespace :relationships do
            relationship :resource, :plan, only: [:create]
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
        get  :billing,   to: "billings#show"
        post :billing,   to: "billings#update"
        get  :tokens,    to: "tokens#generate"
        post :tokens,    to: "tokens#regenerate"
        post :passwords, to: "passwords#reset_password"
        get  :profile,   to: "profiles#show"
        resource :users do
          namespace :actions do
            action :post, :update_password, to: "password#update_password"
            action :post, :reset_password, to: "password#reset_password"
          end
        end
        resource :policies do
          namespace :relationships do
            relationship :delete, :pool, to: "pool#pop"
          end
        end
        resource :keys
        resource :licenses do
          namespace :actions do
            action :get, :validate, to: "permits#validate"
            action :post, :revoke, to: "permits#revoke"
            action :post, :renew, to: "permits#renew"
          end
        end
        resource :machines
        resource :products do
          namespace :relationships do
            relationship :get, :tokens, to: "tokens#generate"
          end
        end
        resource :webhook_endpoints
        resource :webhook_events, only: [:index, :show]
      end
    end
  end

  %w[404 422 500].each do |code|
    match code, to: "errors#show", code: code.to_i, via: :all
  end

  root to: "errors#show", code: 404
end
