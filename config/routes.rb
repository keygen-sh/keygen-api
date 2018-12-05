Rails.application.routes.draw do
  scope module: "api", constraints: { subdomain: "api", format: "jsonapi" } do
    namespace "v1" do
      post "stripe", to: "stripe#receive_webhook"

      # Health checks
      get "health", to: "health#general_health"
      get "health/webhooks", to: "health#webhook_health"
      get "ping", to: "health#general_ping"

      resources "plans", only: [:index, :show]

      resources "accounts", except: [:index] do
        scope module: "accounts/relationships" do
          resource "billing", only: [:show, :update]
          resource "plan", only: [:show, :update]
        end
        member do
          scope "actions", module: "accounts/actions" do
            post "pause-subscription", to: "subscription#pause"
            post "resume-subscription", to: "subscription#resume"
            post "cancel-subscription", to: "subscription#cancel"
            post "renew-subscription", to: "subscription#renew"
          end
        end

        post   "tokens",     to: "tokens#generate"
        put    "tokens",     to: "tokens#regenerate_current"
        put    "tokens/:id", to: "tokens#regenerate"
        get    "tokens",     to: "tokens#index"
        get    "tokens/:id", to: "tokens#show", as: :token
        delete "tokens/:id", to: "tokens#revoke"

        post "passwords", to: "passwords#reset_password"
        get  "profile", to: "profiles#show"

        resources "keys" do
          scope module: "keys/relationships" do
            resource "product", only: [:show]
            resource "policy", only: [:show]
          end
        end

        # NOTE(ezekg) By default, Rails does not allow dots inside our routes, but
        #             we want to support dots since our machines are queryable by
        #             their fingerprint attr, which can be an arbitrary string.
        resources "machines", constraints: { id: /[^\/]*/ } do
          scope module: "machines/relationships" do
            resource "product", only: [:show]
            resource "license", only: [:show]
            resource "user", only: [:show]
          end
        end

        # NOTE(ezekg) Users are queryable by email attr.
        resources "users", constraints: { id: /[^\/]*/ } do
          scope module: "users/relationships" do
            resources "products", only: [:index, :show]
            resources "licenses", only: [:index, :show]
            resources "machines", only: [:index, :show]
            resources "tokens", only: [:index, :show]
          end
          member do
            scope "actions", module: "users/actions" do
              post "update-password", to: "password#update_password"
              post "reset-password", to: "password#reset_password"
            end
          end
        end

        # NOTE(ezekg) Licenses are queryable by their key attr, which can be an
        #             arbitrary string.
        resources "licenses", constraints: { id: /[^\/]*/ } do
          scope module: "licenses/relationships" do
            resources "machines", only: [:index, :show]
            resources "tokens", only: [:index, :show]
            resource "product", only: [:show]
            resource "policy", only: [:show, :update]
            resource "user", only: [:show, :update]
            member do
              post "tokens", to: "tokens#generate"
            end
          end
          member do
            scope "actions", module: "licenses/actions" do
              get "validate", to: "validations#quick_validate_by_id"
              post "validate", to: "validations#validate_by_id"
              delete "revoke", to: "permits#revoke"
              post "renew", to: "permits#renew"
              post "suspend", to: "permits#suspend"
              post "reinstate", to: "permits#reinstate"
              post "check-in", to: "permits#check_in"
              post "increment-usage", to: "uses#increment"
              post "decrement-usage", to: "uses#decrement"
              post "reset-usage", to: "uses#reset"
            end
          end
          collection do
            scope "actions", module: "licenses/actions" do
              post "validate-key", to: "validations#validate_by_key"
            end
          end
        end

        resources "policies" do
          scope module: "policies/relationships" do
            resources "pool", only: [:index, :show], as: "keys" do
              collection do
                delete "/", to: "pool#pop", as: "pop"
              end
            end
            resources "licenses", only: [:index, :show]
            resource "product", only: [:index, :show]
          end
        end

        resources "products" do
          scope module: "products/relationships" do
            resources "policies", only: [:index, :show]
            resources "licenses", only: [:index, :show]
            resources "machines", only: [:index, :show]
            resources "tokens", only: [:index, :show]
            resources "users", only: [:index, :show]
            member do
              post "tokens", to: "tokens#generate"
            end
          end
        end

        resources "webhook_endpoints", path: "webhook-endpoints"
        resources "webhook_events", path: "webhook-events", only: [:index, :show, :destroy] do
          member do
            scope "actions", module: "webhook_events/actions" do
              post "retry", to: "retries#retry"
            end
          end
        end

        resources "request_logs", path: "request-logs", only: [:index, :show]  do
          collection do
            scope "actions", module: "request_logs/actions" do
              get "count", to: "counts#count"
            end
          end
        end

        resources "metrics", only: [:index, :show] do
          collection do
            scope "actions", module: "metrics/actions" do
              get "count", to: "counts#count"
            end
          end
        end

        post "search", to: "searches#search"
      end
    end
  end

  %w[400 404 422 500].each do |code|
    match code, to: "errors#show", code: code.to_i, via: :all
  end

  root to: "errors#show", code: 404
end
