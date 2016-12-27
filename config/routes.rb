Rails.application.routes.draw do
  scope module: "api" do
    namespace "v1", constraints: { subdomain: "api", format: "jsonapi" } do
      post "stripe", to: "stripe#receive_webhook"

      resources "plans", only: [:index, :show]

      resources "accounts" do
        resource "billing", controller: "accounts/relationships/billing", only: [:show, :update]
        resource "plan", controller: "accounts/relationships/plan", only: [:update]
        member do
          scope "actions" do
            post "pause-subscription", to: "accounts/actions/subscription#pause"
            post "resume-subscription", to: "accounts/actions/subscription#resume"
            post "cancel-subscription", to: "accounts/actions/subscription#cancel"
            post "renew-subscription", to: "accounts/actions/subscription#renew"
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
          resource "product", controller: "keys/relationships/product", only: [:show]
          resource "policy", controller: "keys/relationships/policy", only: [:show]
        end

        resources "machines" do
          resource "product", controller: "machines/relationships/product", only: [:show]
          resource "license", controller: "machines/relationships/license", only: [:show]
          resource "user", controller: "machines/relationships/user", only: [:show]
        end

        resources "users" do
          resources "products", controller: "users/relationships/products", only: [:index, :show]
          resources "licenses", controller: "users/relationships/licenses", only: [:index, :show]
          resources "machines", controller: "users/relationships/machines", only: [:index, :show]
          member do
            scope "actions" do
              post "update-password", to: "users/actions/password#update_password"
              post "reset-password", to: "users/actions/password#reset_password"
            end
          end
        end

        resources "licenses" do
          resources "machines", controller: "licenses/relationships/machines", only: [:index, :show]
          resource "product", controller: "licenses/relationships/product", only: [:show]
          resource "policy", controller: "licenses/relationships/policy", only: [:show]
          resource "user", controller: "licenses/relationships/user", only: [:show]
          member do
            scope "actions" do
              get "validate", to: "licenses/actions/validations#validate_by_id"
              delete "revoke", to: "licenses/actions/permits#revoke"
              post "renew", to: "licenses/actions/permits#renew"
            end
          end
          collection do
            scope "actions" do
              post "validate-key", to: "licenses/actions/validations#validate_by_key"
            end
          end
        end

        resources "policies" do
          resources "licenses", controller: "policies/relationships/licenses", only: [:index, :show]
          resource "product", controller: "policies/relationships/product", only: [:index, :show]
          member do
            delete "pool", to: "policies/relationships/pool#pop"
          end
        end

        resources "products" do
          resources "policies", controller: "products/relationships/policies", only: [:index, :show]
          resources "licenses", controller: "products/relationships/licenses", only: [:index, :show]
          resources "machines", controller: "products/relationships/machines", only: [:index, :show]
          resources "users", controller: "products/relationships/users", only: [:index, :show]
          member do
            post "tokens", to: "products/relationships/tokens#generate"
          end
        end

        resources "webhook_endpoints", path: "webhook-endpoints"
        resources "webhook_events", path: "webhook-events", only: [:index, :show] do
          member do
            scope "actions" do
              post "retry", to: "webhook_events/actions/retries#retry"
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

# == Route Map
#
#                           Prefix Verb   URI Pattern                                                  Controller#Action
#                        v1_stripe POST   /v1/stripe(.:format)                                         api/v1/stripe#receive_webhook {:subdomain=>"api", :format=>"json"}
#                         v1_plans GET    /v1/plans(.:format)                                          api/v1/plans#index {:subdomain=>"api", :format=>"json"}
#                          v1_plan GET    /v1/plans/:id(.:format)                                      api/v1/plans#show {:subdomain=>"api", :format=>"json"}
#               billing_v1_account GET    /v1/accounts/:id/billing(.:format)                           api/v1/accounts/billing#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:id/billing(.:format)                           api/v1/accounts/billing#update {:subdomain=>"api", :format=>"json"}
#                  plan_v1_account PUT    /v1/accounts/:id/plan(.:format)                              api/v1/accounts/plan#update {:subdomain=>"api", :format=>"json"}
#    pause_subscription_v1_account POST   /v1/accounts/:id/pause-subscription(.:format)                api/v1/accounts/subscription#pause {:subdomain=>"api", :format=>"json"}
#   resume_subscription_v1_account POST   /v1/accounts/:id/resume-subscription(.:format)               api/v1/accounts/subscription#resume {:subdomain=>"api", :format=>"json"}
#   cancel_subscription_v1_account POST   /v1/accounts/:id/cancel-subscription(.:format)               api/v1/accounts/subscription#cancel {:subdomain=>"api", :format=>"json"}
#    renew_subscription_v1_account POST   /v1/accounts/:id/renew-subscription(.:format)                api/v1/accounts/subscription#renew {:subdomain=>"api", :format=>"json"}
#                v1_account_tokens POST   /v1/accounts/:account_id/tokens(.:format)                    api/v1/tokens#generate {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/tokens(.:format)                    api/v1/tokens#regenerate_current {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/tokens/:id(.:format)                api/v1/tokens#regenerate {:subdomain=>"api", :format=>"json"}
#                                  GET    /v1/accounts/:account_id/tokens(.:format)                    api/v1/tokens#index {:subdomain=>"api", :format=>"json"}
#                 v1_account_token GET    /v1/accounts/:account_id/tokens/:id(.:format)                api/v1/tokens#show {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:account_id/tokens/:id(.:format)                api/v1/tokens#revoke {:subdomain=>"api", :format=>"json"}
#             v1_account_passwords POST   /v1/accounts/:account_id/passwords(.:format)                 api/v1/passwords#reset_password {:subdomain=>"api", :format=>"json"}
#               v1_account_profile GET    /v1/accounts/:account_id/profile(.:format)                   api/v1/profiles#show {:subdomain=>"api", :format=>"json"}
#                  v1_account_keys GET    /v1/accounts/:account_id/keys(.:format)                      api/v1/keys#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts/:account_id/keys(.:format)                      api/v1/keys#create {:subdomain=>"api", :format=>"json"}
#                   v1_account_key GET    /v1/accounts/:account_id/keys/:id(.:format)                  api/v1/keys#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:account_id/keys/:id(.:format)                  api/v1/keys#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/keys/:id(.:format)                  api/v1/keys#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:account_id/keys/:id(.:format)                  api/v1/keys#destroy {:subdomain=>"api", :format=>"json"}
#              v1_account_machines GET    /v1/accounts/:account_id/machines(.:format)                  api/v1/machines#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts/:account_id/machines(.:format)                  api/v1/machines#create {:subdomain=>"api", :format=>"json"}
#               v1_account_machine GET    /v1/accounts/:account_id/machines/:id(.:format)              api/v1/machines#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:account_id/machines/:id(.:format)              api/v1/machines#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/machines/:id(.:format)              api/v1/machines#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:account_id/machines/:id(.:format)              api/v1/machines#destroy {:subdomain=>"api", :format=>"json"}
#     v1_account_webhook_endpoints GET    /v1/accounts/:account_id/webhook-endpoints(.:format)         api/v1/webhook_endpoints#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts/:account_id/webhook-endpoints(.:format)         api/v1/webhook_endpoints#create {:subdomain=>"api", :format=>"json"}
#      v1_account_webhook_endpoint GET    /v1/accounts/:account_id/webhook-endpoints/:id(.:format)     api/v1/webhook_endpoints#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:account_id/webhook-endpoints/:id(.:format)     api/v1/webhook_endpoints#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/webhook-endpoints/:id(.:format)     api/v1/webhook_endpoints#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:account_id/webhook-endpoints/:id(.:format)     api/v1/webhook_endpoints#destroy {:subdomain=>"api", :format=>"json"}
#  update_password_v1_account_user POST   /v1/accounts/:account_id/users/:id/update-password(.:format) api/v1/users/password#update_password {:subdomain=>"api", :format=>"json"}
#   reset_password_v1_account_user POST   /v1/accounts/:account_id/users/:id/reset-password(.:format)  api/v1/users/password#reset_password {:subdomain=>"api", :format=>"json"}
#                 v1_account_users GET    /v1/accounts/:account_id/users(.:format)                     api/v1/users#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts/:account_id/users(.:format)                     api/v1/users#create {:subdomain=>"api", :format=>"json"}
#                  v1_account_user GET    /v1/accounts/:account_id/users/:id(.:format)                 api/v1/users#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:account_id/users/:id(.:format)                 api/v1/users#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/users/:id(.:format)                 api/v1/users#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:account_id/users/:id(.:format)                 api/v1/users#destroy {:subdomain=>"api", :format=>"json"}
#      validate_v1_account_license GET    /v1/accounts/:account_id/licenses/:id/validate(.:format)     api/v1/licenses/validations#validate_by_id {:subdomain=>"api", :format=>"json"}
#        revoke_v1_account_license DELETE /v1/accounts/:account_id/licenses/:id/revoke(.:format)       api/v1/licenses/permits#revoke {:subdomain=>"api", :format=>"json"}
#         renew_v1_account_license POST   /v1/accounts/:account_id/licenses/:id/renew(.:format)        api/v1/licenses/permits#renew {:subdomain=>"api", :format=>"json"}
# validate_key_v1_account_licenses POST   /v1/accounts/:account_id/licenses/validate-key(.:format)     api/v1/licenses/validations#validate_by_key {:subdomain=>"api", :format=>"json"}
#              v1_account_licenses GET    /v1/accounts/:account_id/licenses(.:format)                  api/v1/licenses#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts/:account_id/licenses(.:format)                  api/v1/licenses#create {:subdomain=>"api", :format=>"json"}
#               v1_account_license GET    /v1/accounts/:account_id/licenses/:id(.:format)              api/v1/licenses#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:account_id/licenses/:id(.:format)              api/v1/licenses#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/licenses/:id(.:format)              api/v1/licenses#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:account_id/licenses/:id(.:format)              api/v1/licenses#destroy {:subdomain=>"api", :format=>"json"}
#           pool_v1_account_policy DELETE /v1/accounts/:account_id/policies/:id/pool(.:format)         api/v1/policies/pool#pop {:subdomain=>"api", :format=>"json"}
#              v1_account_policies GET    /v1/accounts/:account_id/policies(.:format)                  api/v1/policies#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts/:account_id/policies(.:format)                  api/v1/policies#create {:subdomain=>"api", :format=>"json"}
#                v1_account_policy GET    /v1/accounts/:account_id/policies/:id(.:format)              api/v1/policies#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:account_id/policies/:id(.:format)              api/v1/policies#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/policies/:id(.:format)              api/v1/policies#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:account_id/policies/:id(.:format)              api/v1/policies#destroy {:subdomain=>"api", :format=>"json"}
#        tokens_v1_account_product POST   /v1/accounts/:account_id/products/:id/tokens(.:format)       api/v1/products/tokens#generate {:subdomain=>"api", :format=>"json"}
#              v1_account_products GET    /v1/accounts/:account_id/products(.:format)                  api/v1/products#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts/:account_id/products(.:format)                  api/v1/products#create {:subdomain=>"api", :format=>"json"}
#               v1_account_product GET    /v1/accounts/:account_id/products/:id(.:format)              api/v1/products#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:account_id/products/:id(.:format)              api/v1/products#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:account_id/products/:id(.:format)              api/v1/products#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:account_id/products/:id(.:format)              api/v1/products#destroy {:subdomain=>"api", :format=>"json"}
#   retry_v1_account_webhook_event POST   /v1/accounts/:account_id/webhook-events/:id/retry(.:format)  api/v1/webhook_events/retries#retry {:subdomain=>"api", :format=>"json"}
#        v1_account_webhook_events GET    /v1/accounts/:account_id/webhook-events(.:format)            api/v1/webhook_events#index {:subdomain=>"api", :format=>"json"}
#         v1_account_webhook_event GET    /v1/accounts/:account_id/webhook-events/:id(.:format)        api/v1/webhook_events#show {:subdomain=>"api", :format=>"json"}
#                      v1_accounts GET    /v1/accounts(.:format)                                       api/v1/accounts#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts(.:format)                                       api/v1/accounts#create {:subdomain=>"api", :format=>"json"}
#                       v1_account GET    /v1/accounts/:id(.:format)                                   api/v1/accounts#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:id(.:format)                                   api/v1/accounts#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:id(.:format)                                   api/v1/accounts#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:id(.:format)                                   api/v1/accounts#destroy {:subdomain=>"api", :format=>"json"}
#                                         /404(.:format)                                               errors#show {:code=>404}
#                                         /422(.:format)                                               errors#show {:code=>422}
#                                         /500(.:format)                                               errors#show {:code=>500}
#                             root GET    /                                                            errors#show {:code=>404}
#
