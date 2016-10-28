Rails.application.routes.draw do
  scope module: "api" do
    namespace "v1", constraints: { format: "json" } do

      constraints lambda { |r| r.subdomain.empty? } do
        post "stripe", to: "stripe#receive_webhook"

        resources "plans", only: [:index, :show]

        resources "accounts" do
          scope module: "accounts" do
            namespace "relationships" do
              get "billing", to: "billing#show"
              post "billing", to: "billing#update"
              post "plan", to: "plan#update"
            end
            namespace "actions" do
              post "pause", to: "subscription#pause"
              post "resume", to: "subscription#resume"
              post "cancel", to: "subscription#cancel"
              post "renew", to: "subscription#renew"
            end
          end
        end
      end

      constraints lambda { |r| r.subdomain.present? } do
        get  "tokens", to: "tokens#generate"
        post "tokens", to: "tokens#regenerate"

        post "passwords", to: "passwords#reset_password"
        get  "profile", to: "profiles#show"

        resources "keys"
        resources "machines"
        resources "webhook_endpoints", path: "webhook-endpoints"

        resources "users" do
          scope module: "users" do
            namespace "actions" do
              post "update-password", to: "password#update_password"
              post "reset-password", to: "password#reset_password"
            end
          end
        end

        resources "licenses" do
          scope module: "licenses" do
            namespace "actions" do
              get "validate", to: "permits#validate"
              post "revoke", to: "permits#revoke"
              post "renew", to: "permits#renew"
            end
          end
        end

        resources "policies" do
          scope module: "policies" do
            namespace "relationships" do
              delete "pool", to: "pool#pop"
            end
          end
        end

        resources "products" do
          scope module: "products" do
            namespace "relationships" do
              get "tokens", to: "tokens#generate"
            end
          end
        end

        resources "webhook_events", path: "webhook-events", only: [:index, :show] do
          scope module: "webhook_events" do
            namespace "actions" do
              post "retry", to: "retries#retry"
            end
          end
        end
      end
    end
  end

  %w[404 422 500].each do |code|
    match code, to: "errors#show", code: code.to_i, via: :all
  end

  root to: "errors#show", code: 404
end
