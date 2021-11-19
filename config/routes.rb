# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq_unique_jobs/web'

Rails.application.routes.draw do
  bin_constraints =
    if !Rails.env.development?
      { constraints: { subdomain: %w[bin get], format: "jsonapi" } }
    else
      { constraints: { format: "jsonapi" } }
    end
  api_constraints =
    if !Rails.env.development?
      { constraints: { subdomain: "api", format: "jsonapi" } }
    else
      { constraints: { format: "jsonapi" } }
    end

  mount Sidekiq::Web, at: '/-/sidekiq'

  namespace "-" do
    post 'csp-reports', to: proc { |env|
      bytesize = env['rack.input'].size
      next [422, {}, []] if bytesize > 10.kilobytes

      payload = env['rack.input'].read
      env['rack.input'].rewind

      Rails.logger.warn "[csp-reports] CSP violation: size=#{bytesize} payload=#{payload}"

      [202, {}, []]
    }
  end

  scope module: "api", **api_constraints do
    namespace "v1" do
      post "stripe", to: "stripe#receive_webhook"

      # Health checks
      get "health", to: "health#general_health"
      get "health/webhooks", to: "health#webhook_health"
      get "ping", to: "health#general_ping"

      # Recover
      post "recover", to: "recoveries#recover"

      resources "plans", only: [:index, :show]

      resources "accounts", except: [:index] do
        scope module: "accounts/relationships" do
          resource "billing", only: [:show, :update]
          resource "plan", only: [:show, :update]
        end
        member do
          scope "actions", module: "accounts/actions" do
            post "manage-subscription", to: "subscription#manage"
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
        get  "me", to: "profiles#me"

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
          member do
            scope "actions", module: "machines/actions" do
              post "generate-offline-proof", to: "proofs#generate_offline_proof"
              post "reset-heartbeat", to: "heartbeats#reset_heartbeat"
              post "ping-heartbeat", to: "heartbeats#ping_heartbeat"
            end
          end
        end

        # NOTE(ezekg) Users are queryable by email attr.
        resources "users", constraints: { id: /[^\/]*/ } do
          scope module: "users/relationships" do
            resources "second_factors", path: "second-factors", only: [:index, :show, :create, :update, :destroy]
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
            resources "entitlements", only: [:index, :show] do
              collection do
                post "/", to: "entitlements#attach", as: "attach"
                delete "/", to: "entitlements#detach", as: "detach"
              end
            end
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
            resource "product", only: [:show]
            resources "entitlements", only: [:index, :show] do
              collection do
                post "/", to: "entitlements#attach", as: "attach"
                delete "/", to: "entitlements#detach", as: "detach"
              end
            end
          end
        end

        resources "products" do
          scope module: "products/relationships" do
            resources "policies", only: [:index, :show]
            resources "licenses", only: [:index, :show]
            resources "machines", only: [:index, :show]
            resources "tokens", only: [:index, :show]
            resources "users", only: [:index, :show]
            resources "artifacts", constraints: { id: /.*/ }, only: [:index, :show]
            resources "platforms", only: [:index, :show]
            resources "releases", only: [:index, :show]
            resources "channels", only: [:index, :show]
            member do
              post "tokens", to: "tokens#generate"
            end
          end
        end

        resources "releases" do
          collection do
            put "/", to: "releases#upsert", as: "upsert"
          end
          scope module: "releases/relationships" do
            resources "constraints", only: [:index, :show] do
              collection do
                post "/", to: "constraints#attach", as: "attach"
                delete "/", to: "constraints#detach", as: "detach"
              end
            end
            resource "artifact", only: [:show, :destroy] do
              put :create
            end
            resource "product", only: [:show]
          end
          member do
            scope "actions", module: "releases/actions" do
              get "upgrade", to: "upgrades#check_for_upgrade_by_id"
            end
          end
          collection do
            scope "actions", module: "releases/actions" do
              get "upgrade", to: "upgrades#check_for_upgrade_by_query"
            end
          end
        end

        resources "artifacts", constraints: { id: /.*/ }, only: [:index, :show]
        resources "platforms", only: [:index, :show]
        resources "channels", only: [:index, :show]

        resources "entitlements"

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

        resources "analytics", only: [] do
          collection do
            scope "actions", module: "analytics/actions" do
              get "top-licenses-by-volume", to: "counts#top_licenses_by_volume"
              get "top-urls-by-volume", to: "counts#top_urls_by_volume"
              get "top-ips-by-volume", to: "counts#top_ips_by_volume"
              get "count", to: "counts#count"
            end
          end
        end

        post "search", to: "searches#search"
      end
    end
  end

  scope module: "bin", **bin_constraints do
    get ":account_id/:artifact_id",
      constraints: { account_id: /[^\/]*/, artifact_id: /.*/ },
      to: "bin#show"
  end

  %w[500 503].each do |code|
    match code, to: "errors#show", code: code.to_i, via: :all
  end

  match '*unmatched_route', to: "errors#show", code: 404, via: :all
  root to: "errors#show", code: 404, via: :all
end
