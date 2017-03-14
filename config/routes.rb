Rails.application.routes.draw do
  # Lets Encrypt cert challenge
  get ".well-known/acme-challenge/#{ENV["LETS_ENCRYPT_CHALLENGE"]}", to: -> (*) { [200, {}, [ENV["LETS_ENCRYPT_ANSWER"]]] }

  # constraints -> (req) { req.format.symbol != :jsonapi } do
  #   match "*bad_request", to: "errors#show", code: 400, via: [:get, :post, :patch, :put, :delete, :head, :options]
  # end

  scope module: "api", constraints: { subdomain: "api", format: "jsonapi" } do
    namespace "v1" do
      post "stripe", to: "stripe#receive_webhook"

      # Health check
      get "health", to: -> (*) { [204, {}, []] }

      resources "plans", only: [:index, :show]

      resources "accounts", except: [:index] do
        scope module: "accounts/relationships" do
          resource "billing", only: [:show, :update]
          resource "plan", only: [:show, :update]
        end
        member do
          scope "actions", module: "accounts/actions" do
            post "accept-invitation", to: "invitations#accept"
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

        resources "machines" do
          scope module: "machines/relationships" do
            resource "product", only: [:show]
            resource "license", only: [:show]
            resource "user", only: [:show]
          end
        end

        resources "users" do
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

        resources "licenses" do
          scope module: "licenses/relationships" do
            resources "machines", only: [:index, :show]
            resource "product", only: [:show]
            resource "policy", only: [:show]
            resource "user", only: [:show]
          end
          member do
            scope "actions", module: "licenses/actions" do
              get "validate", to: "validations#validate_by_id"
              delete "revoke", to: "permits#revoke"
              post "renew", to: "permits#renew"
              post "suspend", to: "permits#suspend"
              post "reinstate", to: "permits#reinstate"
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
        resources "webhook_events", path: "webhook-events", only: [:index, :show] do
          member do
            scope "actions", module: "webhook_events/actions" do
              post "retry", to: "retries#retry"
            end
          end
        end

        resources "metrics", only: [:index, :show]
      end
    end
  end

  %w[400 404 422 500].each do |code|
    match code, to: "errors#show", code: code.to_i, via: :all
  end

  root to: "errors#show", code: 404
end

# == Route Map
#
#                           Prefix Verb   URI Pattern                                                          Controller#Action
#                                  GET    /.well-known/acme-challenge(.:format)                                #<Proc:0x007f965d463408@/Users/gabrielse/code/keygen/api/config/routes.rb:3 (lambda)>
#                        v1_stripe POST   /v1/stripe(.:format)                                                 api/v1/stripe#receive_webhook {:subdomain=>"api", :format=>"jsonapi"}
#                        v1_health GET    /v1/health(.:format)                                                 #<Proc:0x007f965d492b68@/Users/gabrielse/code/keygen/api/config/routes.rb:14 (lambda)> {:subdomain=>"api", :format=>"jsonapi"}
#                         v1_plans GET    /v1/plans(.:format)                                                  api/v1/plans#index {:subdomain=>"api", :format=>"jsonapi"}
#                          v1_plan GET    /v1/plans/:id(.:format)                                              api/v1/plans#show {:subdomain=>"api", :format=>"jsonapi"}
#               v1_account_billing GET    /v1/accounts/:account_id/billing(.:format)                           api/v1/accounts/relationships/billings#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/billing(.:format)                           api/v1/accounts/relationships/billings#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/billing(.:format)                           api/v1/accounts/relationships/billings#update {:subdomain=>"api", :format=>"jsonapi"}
#                  v1_account_plan GET    /v1/accounts/:account_id/plan(.:format)                              api/v1/accounts/relationships/plans#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/plan(.:format)                              api/v1/accounts/relationships/plans#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/plan(.:format)                              api/v1/accounts/relationships/plans#update {:subdomain=>"api", :format=>"jsonapi"}
#     accept_invitation_v1_account POST   /v1/accounts/:id/actions/accept-invitation(.:format)                 api/v1/accounts/actions/invitations#accept {:subdomain=>"api", :format=>"jsonapi"}
#    pause_subscription_v1_account POST   /v1/accounts/:id/actions/pause-subscription(.:format)                api/v1/accounts/actions/subscription#pause {:subdomain=>"api", :format=>"jsonapi"}
#   resume_subscription_v1_account POST   /v1/accounts/:id/actions/resume-subscription(.:format)               api/v1/accounts/actions/subscription#resume {:subdomain=>"api", :format=>"jsonapi"}
#   cancel_subscription_v1_account POST   /v1/accounts/:id/actions/cancel-subscription(.:format)               api/v1/accounts/actions/subscription#cancel {:subdomain=>"api", :format=>"jsonapi"}
#    renew_subscription_v1_account POST   /v1/accounts/:id/actions/renew-subscription(.:format)                api/v1/accounts/actions/subscription#renew {:subdomain=>"api", :format=>"jsonapi"}
#                v1_account_tokens POST   /v1/accounts/:account_id/tokens(.:format)                            api/v1/tokens#generate {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/tokens(.:format)                            api/v1/tokens#regenerate_current {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/tokens/:id(.:format)                        api/v1/tokens#regenerate {:subdomain=>"api", :format=>"jsonapi"}
#                                  GET    /v1/accounts/:account_id/tokens(.:format)                            api/v1/tokens#index {:subdomain=>"api", :format=>"jsonapi"}
#                 v1_account_token GET    /v1/accounts/:account_id/tokens/:id(.:format)                        api/v1/tokens#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:account_id/tokens/:id(.:format)                        api/v1/tokens#revoke {:subdomain=>"api", :format=>"jsonapi"}
#             v1_account_passwords POST   /v1/accounts/:account_id/passwords(.:format)                         api/v1/passwords#reset_password {:subdomain=>"api", :format=>"jsonapi"}
#               v1_account_profile GET    /v1/accounts/:account_id/profile(.:format)                           api/v1/profiles#show {:subdomain=>"api", :format=>"jsonapi"}
#           v1_account_key_product GET    /v1/accounts/:account_id/keys/:key_id/product(.:format)              api/v1/keys/relationships/products#show {:subdomain=>"api", :format=>"jsonapi"}
#            v1_account_key_policy GET    /v1/accounts/:account_id/keys/:key_id/policy(.:format)               api/v1/keys/relationships/policies#show {:subdomain=>"api", :format=>"jsonapi"}
#                  v1_account_keys GET    /v1/accounts/:account_id/keys(.:format)                              api/v1/keys#index {:subdomain=>"api", :format=>"jsonapi"}
#                                  POST   /v1/accounts/:account_id/keys(.:format)                              api/v1/keys#create {:subdomain=>"api", :format=>"jsonapi"}
#                   v1_account_key GET    /v1/accounts/:account_id/keys/:id(.:format)                          api/v1/keys#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/keys/:id(.:format)                          api/v1/keys#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/keys/:id(.:format)                          api/v1/keys#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:account_id/keys/:id(.:format)                          api/v1/keys#destroy {:subdomain=>"api", :format=>"jsonapi"}
#       v1_account_machine_product GET    /v1/accounts/:account_id/machines/:machine_id/product(.:format)      api/v1/machines/relationships/products#show {:subdomain=>"api", :format=>"jsonapi"}
#       v1_account_machine_license GET    /v1/accounts/:account_id/machines/:machine_id/license(.:format)      api/v1/machines/relationships/licenses#show {:subdomain=>"api", :format=>"jsonapi"}
#          v1_account_machine_user GET    /v1/accounts/:account_id/machines/:machine_id/user(.:format)         api/v1/machines/relationships/users#show {:subdomain=>"api", :format=>"jsonapi"}
#              v1_account_machines GET    /v1/accounts/:account_id/machines(.:format)                          api/v1/machines#index {:subdomain=>"api", :format=>"jsonapi"}
#                                  POST   /v1/accounts/:account_id/machines(.:format)                          api/v1/machines#create {:subdomain=>"api", :format=>"jsonapi"}
#               v1_account_machine GET    /v1/accounts/:account_id/machines/:id(.:format)                      api/v1/machines#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/machines/:id(.:format)                      api/v1/machines#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/machines/:id(.:format)                      api/v1/machines#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:account_id/machines/:id(.:format)                      api/v1/machines#destroy {:subdomain=>"api", :format=>"jsonapi"}
#         v1_account_user_products GET    /v1/accounts/:account_id/users/:user_id/products(.:format)           api/v1/users/relationships/products#index {:subdomain=>"api", :format=>"jsonapi"}
#          v1_account_user_product GET    /v1/accounts/:account_id/users/:user_id/products/:id(.:format)       api/v1/users/relationships/products#show {:subdomain=>"api", :format=>"jsonapi"}
#         v1_account_user_licenses GET    /v1/accounts/:account_id/users/:user_id/licenses(.:format)           api/v1/users/relationships/licenses#index {:subdomain=>"api", :format=>"jsonapi"}
#          v1_account_user_license GET    /v1/accounts/:account_id/users/:user_id/licenses/:id(.:format)       api/v1/users/relationships/licenses#show {:subdomain=>"api", :format=>"jsonapi"}
#         v1_account_user_machines GET    /v1/accounts/:account_id/users/:user_id/machines(.:format)           api/v1/users/relationships/machines#index {:subdomain=>"api", :format=>"jsonapi"}
#          v1_account_user_machine GET    /v1/accounts/:account_id/users/:user_id/machines/:id(.:format)       api/v1/users/relationships/machines#show {:subdomain=>"api", :format=>"jsonapi"}
#           v1_account_user_tokens GET    /v1/accounts/:account_id/users/:user_id/tokens(.:format)             api/v1/users/relationships/tokens#index {:subdomain=>"api", :format=>"jsonapi"}
#            v1_account_user_token GET    /v1/accounts/:account_id/users/:user_id/tokens/:id(.:format)         api/v1/users/relationships/tokens#show {:subdomain=>"api", :format=>"jsonapi"}
#  update_password_v1_account_user POST   /v1/accounts/:account_id/users/:id/actions/update-password(.:format) api/v1/users/actions/password#update_password {:subdomain=>"api", :format=>"jsonapi"}
#   reset_password_v1_account_user POST   /v1/accounts/:account_id/users/:id/actions/reset-password(.:format)  api/v1/users/actions/password#reset_password {:subdomain=>"api", :format=>"jsonapi"}
#                 v1_account_users GET    /v1/accounts/:account_id/users(.:format)                             api/v1/users#index {:subdomain=>"api", :format=>"jsonapi"}
#                                  POST   /v1/accounts/:account_id/users(.:format)                             api/v1/users#create {:subdomain=>"api", :format=>"jsonapi"}
#                  v1_account_user GET    /v1/accounts/:account_id/users/:id(.:format)                         api/v1/users#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/users/:id(.:format)                         api/v1/users#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/users/:id(.:format)                         api/v1/users#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:account_id/users/:id(.:format)                         api/v1/users#destroy {:subdomain=>"api", :format=>"jsonapi"}
#      v1_account_license_machines GET    /v1/accounts/:account_id/licenses/:license_id/machines(.:format)     api/v1/licenses/relationships/machines#index {:subdomain=>"api", :format=>"jsonapi"}
#       v1_account_license_machine GET    /v1/accounts/:account_id/licenses/:license_id/machines/:id(.:format) api/v1/licenses/relationships/machines#show {:subdomain=>"api", :format=>"jsonapi"}
#       v1_account_license_product GET    /v1/accounts/:account_id/licenses/:license_id/product(.:format)      api/v1/licenses/relationships/products#show {:subdomain=>"api", :format=>"jsonapi"}
#        v1_account_license_policy GET    /v1/accounts/:account_id/licenses/:license_id/policy(.:format)       api/v1/licenses/relationships/policies#show {:subdomain=>"api", :format=>"jsonapi"}
#          v1_account_license_user GET    /v1/accounts/:account_id/licenses/:license_id/user(.:format)         api/v1/licenses/relationships/users#show {:subdomain=>"api", :format=>"jsonapi"}
#      validate_v1_account_license GET    /v1/accounts/:account_id/licenses/:id/actions/validate(.:format)     api/v1/licenses/actions/validations#validate_by_id {:subdomain=>"api", :format=>"jsonapi"}
#        revoke_v1_account_license DELETE /v1/accounts/:account_id/licenses/:id/actions/revoke(.:format)       api/v1/licenses/actions/permits#revoke {:subdomain=>"api", :format=>"jsonapi"}
#         renew_v1_account_license POST   /v1/accounts/:account_id/licenses/:id/actions/renew(.:format)        api/v1/licenses/actions/permits#renew {:subdomain=>"api", :format=>"jsonapi"}
#       suspend_v1_account_license POST   /v1/accounts/:account_id/licenses/:id/actions/suspend(.:format)      api/v1/licenses/actions/permits#suspend {:subdomain=>"api", :format=>"jsonapi"}
#     reinstate_v1_account_license POST   /v1/accounts/:account_id/licenses/:id/actions/reinstate(.:format)    api/v1/licenses/actions/permits#reinstate {:subdomain=>"api", :format=>"jsonapi"}
# validate_key_v1_account_licenses POST   /v1/accounts/:account_id/licenses/actions/validate-key(.:format)     api/v1/licenses/actions/validations#validate_by_key {:subdomain=>"api", :format=>"jsonapi"}
#              v1_account_licenses GET    /v1/accounts/:account_id/licenses(.:format)                          api/v1/licenses#index {:subdomain=>"api", :format=>"jsonapi"}
#                                  POST   /v1/accounts/:account_id/licenses(.:format)                          api/v1/licenses#create {:subdomain=>"api", :format=>"jsonapi"}
#               v1_account_license GET    /v1/accounts/:account_id/licenses/:id(.:format)                      api/v1/licenses#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/licenses/:id(.:format)                      api/v1/licenses#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/licenses/:id(.:format)                      api/v1/licenses#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:account_id/licenses/:id(.:format)                      api/v1/licenses#destroy {:subdomain=>"api", :format=>"jsonapi"}
#       pop_v1_account_policy_keys DELETE /v1/accounts/:account_id/policies/:policy_id/pool(.:format)          api/v1/policies/relationships/pool#pop {:subdomain=>"api", :format=>"jsonapi"}
#           v1_account_policy_keys GET    /v1/accounts/:account_id/policies/:policy_id/pool(.:format)          api/v1/policies/relationships/pool#index {:subdomain=>"api", :format=>"jsonapi"}
#            v1_account_policy_key GET    /v1/accounts/:account_id/policies/:policy_id/pool/:id(.:format)      api/v1/policies/relationships/pool#show {:subdomain=>"api", :format=>"jsonapi"}
#       v1_account_policy_licenses GET    /v1/accounts/:account_id/policies/:policy_id/licenses(.:format)      api/v1/policies/relationships/licenses#index {:subdomain=>"api", :format=>"jsonapi"}
#        v1_account_policy_license GET    /v1/accounts/:account_id/policies/:policy_id/licenses/:id(.:format)  api/v1/policies/relationships/licenses#show {:subdomain=>"api", :format=>"jsonapi"}
#        v1_account_policy_product GET    /v1/accounts/:account_id/policies/:policy_id/product(.:format)       api/v1/policies/relationships/products#show {:subdomain=>"api", :format=>"jsonapi"}
#              v1_account_policies GET    /v1/accounts/:account_id/policies(.:format)                          api/v1/policies#index {:subdomain=>"api", :format=>"jsonapi"}
#                                  POST   /v1/accounts/:account_id/policies(.:format)                          api/v1/policies#create {:subdomain=>"api", :format=>"jsonapi"}
#                v1_account_policy GET    /v1/accounts/:account_id/policies/:id(.:format)                      api/v1/policies#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/policies/:id(.:format)                      api/v1/policies#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/policies/:id(.:format)                      api/v1/policies#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:account_id/policies/:id(.:format)                      api/v1/policies#destroy {:subdomain=>"api", :format=>"jsonapi"}
#      v1_account_product_policies GET    /v1/accounts/:account_id/products/:product_id/policies(.:format)     api/v1/products/relationships/policies#index {:subdomain=>"api", :format=>"jsonapi"}
#        v1_account_product_policy GET    /v1/accounts/:account_id/products/:product_id/policies/:id(.:format) api/v1/products/relationships/policies#show {:subdomain=>"api", :format=>"jsonapi"}
#      v1_account_product_licenses GET    /v1/accounts/:account_id/products/:product_id/licenses(.:format)     api/v1/products/relationships/licenses#index {:subdomain=>"api", :format=>"jsonapi"}
#       v1_account_product_license GET    /v1/accounts/:account_id/products/:product_id/licenses/:id(.:format) api/v1/products/relationships/licenses#show {:subdomain=>"api", :format=>"jsonapi"}
#      v1_account_product_machines GET    /v1/accounts/:account_id/products/:product_id/machines(.:format)     api/v1/products/relationships/machines#index {:subdomain=>"api", :format=>"jsonapi"}
#       v1_account_product_machine GET    /v1/accounts/:account_id/products/:product_id/machines/:id(.:format) api/v1/products/relationships/machines#show {:subdomain=>"api", :format=>"jsonapi"}
#        v1_account_product_tokens GET    /v1/accounts/:account_id/products/:product_id/tokens(.:format)       api/v1/products/relationships/tokens#index {:subdomain=>"api", :format=>"jsonapi"}
#         v1_account_product_token GET    /v1/accounts/:account_id/products/:product_id/tokens/:id(.:format)   api/v1/products/relationships/tokens#show {:subdomain=>"api", :format=>"jsonapi"}
#         v1_account_product_users GET    /v1/accounts/:account_id/products/:product_id/users(.:format)        api/v1/products/relationships/users#index {:subdomain=>"api", :format=>"jsonapi"}
#          v1_account_product_user GET    /v1/accounts/:account_id/products/:product_id/users/:id(.:format)    api/v1/products/relationships/users#show {:subdomain=>"api", :format=>"jsonapi"}
#        tokens_v1_account_product POST   /v1/accounts/:account_id/products/:id/tokens(.:format)               api/v1/products/relationships/tokens#generate {:subdomain=>"api", :format=>"jsonapi"}
#              v1_account_products GET    /v1/accounts/:account_id/products(.:format)                          api/v1/products#index {:subdomain=>"api", :format=>"jsonapi"}
#                                  POST   /v1/accounts/:account_id/products(.:format)                          api/v1/products#create {:subdomain=>"api", :format=>"jsonapi"}
#               v1_account_product GET    /v1/accounts/:account_id/products/:id(.:format)                      api/v1/products#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/products/:id(.:format)                      api/v1/products#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/products/:id(.:format)                      api/v1/products#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:account_id/products/:id(.:format)                      api/v1/products#destroy {:subdomain=>"api", :format=>"jsonapi"}
#     v1_account_webhook_endpoints GET    /v1/accounts/:account_id/webhook-endpoints(.:format)                 api/v1/webhook_endpoints#index {:subdomain=>"api", :format=>"jsonapi"}
#                                  POST   /v1/accounts/:account_id/webhook-endpoints(.:format)                 api/v1/webhook_endpoints#create {:subdomain=>"api", :format=>"jsonapi"}
#      v1_account_webhook_endpoint GET    /v1/accounts/:account_id/webhook-endpoints/:id(.:format)             api/v1/webhook_endpoints#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:account_id/webhook-endpoints/:id(.:format)             api/v1/webhook_endpoints#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:account_id/webhook-endpoints/:id(.:format)             api/v1/webhook_endpoints#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:account_id/webhook-endpoints/:id(.:format)             api/v1/webhook_endpoints#destroy {:subdomain=>"api", :format=>"jsonapi"}
#   retry_v1_account_webhook_event POST   /v1/accounts/:account_id/webhook-events/:id/actions/retry(.:format)  api/v1/webhook_events/actions/retries#retry {:subdomain=>"api", :format=>"jsonapi"}
#        v1_account_webhook_events GET    /v1/accounts/:account_id/webhook-events(.:format)                    api/v1/webhook_events#index {:subdomain=>"api", :format=>"jsonapi"}
#         v1_account_webhook_event GET    /v1/accounts/:account_id/webhook-events/:id(.:format)                api/v1/webhook_events#show {:subdomain=>"api", :format=>"jsonapi"}
#               v1_account_metrics GET    /v1/accounts/:account_id/metrics(.:format)                           api/v1/metrics#index {:subdomain=>"api", :format=>"jsonapi"}
#                v1_account_metric GET    /v1/accounts/:account_id/metrics/:id(.:format)                       api/v1/metrics#show {:subdomain=>"api", :format=>"jsonapi"}
#                      v1_accounts POST   /v1/accounts(.:format)                                               api/v1/accounts#create {:subdomain=>"api", :format=>"jsonapi"}
#                       v1_account GET    /v1/accounts/:id(.:format)                                           api/v1/accounts#show {:subdomain=>"api", :format=>"jsonapi"}
#                                  PATCH  /v1/accounts/:id(.:format)                                           api/v1/accounts#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  PUT    /v1/accounts/:id(.:format)                                           api/v1/accounts#update {:subdomain=>"api", :format=>"jsonapi"}
#                                  DELETE /v1/accounts/:id(.:format)                                           api/v1/accounts#destroy {:subdomain=>"api", :format=>"jsonapi"}
#                                         /400(.:format)                                                       errors#show {:code=>400}
#                                         /404(.:format)                                                       errors#show {:code=>404}
#                                         /422(.:format)                                                       errors#show {:code=>422}
#                                         /500(.:format)                                                       errors#show {:code=>500}
#                             root GET    /                                                                    errors#show {:code=>404}
#
