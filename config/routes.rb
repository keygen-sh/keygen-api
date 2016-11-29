Rails.application.routes.draw do
  scope module: "api" do
    namespace "v1", constraints: { subdomain: "api", format: "json" } do
      post "stripe", to: "stripe#receive_webhook"

      resources "plans", only: [:index, :show]

      resources "accounts" do
        member do
          get "billing", to: "accounts/billing#show"
          patch "billing", to: "accounts/billing#update"
          put "plan", to: "accounts/plan#update"
          post "pause-subscription", to: "accounts/subscription#pause"
          post "resume-subscription", to: "accounts/subscription#resume"
          post "cancel-subscription", to: "accounts/subscription#cancel"
          post "renew-subscription", to: "accounts/subscription#renew"
        end
      end

      post   "tokens",     to: "tokens#generate"
      put    "tokens",     to: "tokens#regenerate_current"
      put    "tokens/:id", to: "tokens#regenerate"
      get    "tokens",     to: "tokens#index"
      get    "tokens/:id", to: "tokens#show"
      delete "tokens/:id", to: "tokens#revoke"

      post "passwords", to: "passwords#reset_password"
      get  "profile", to: "profiles#show"

      resources "keys"
      resources "machines"
      resources "webhook_endpoints", path: "webhook-endpoints"

      resources "users" do
        member do
          post "update-password", to: "users/password#update_password"
          post "reset-password", to: "users/password#reset_password"
        end
      end

      resources "licenses" do
        member do
          get "validate", to: "licenses/validations#validate_by_id"
          delete "revoke", to: "licenses/permits#revoke"
          post "renew", to: "licenses/permits#renew"
        end
        collection do
          post "validate-key", to: "licenses/validations#validate_by_key"
        end
      end

      resources "policies" do
        member do
          delete "pool", to: "policies/pool#pop"
        end
      end

      resources "products" do
        member do
          post "tokens", to: "products/tokens#generate"
        end
      end

      resources "webhook_events", path: "webhook-events", only: [:index, :show] do
        member do
          post "retry", to: "webhook_events/retries#retry"
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
#                         Prefix Verb   URI Pattern                                    Controller#Action
#                      v1_stripe POST   /v1/stripe(.:format)                           api/v1/stripe#receive_webhook {:subdomain=>"api", :format=>"json"}
#                       v1_plans GET    /v1/plans(.:format)                            api/v1/plans#index {:subdomain=>"api", :format=>"json"}
#                        v1_plan GET    /v1/plans/:id(.:format)                        api/v1/plans#show {:subdomain=>"api", :format=>"json"}
#             billing_v1_account GET    /v1/accounts/:id/billing(.:format)             api/v1/accounts/billing#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/accounts/:id/billing(.:format)             api/v1/accounts/billing#update {:subdomain=>"api", :format=>"json"}
#                plan_v1_account PUT    /v1/accounts/:id/plan(.:format)                api/v1/accounts/plan#update {:subdomain=>"api", :format=>"json"}
#  pause_subscription_v1_account POST   /v1/accounts/:id/pause-subscription(.:format)  api/v1/accounts/subscription#pause {:subdomain=>"api", :format=>"json"}
# resume_subscription_v1_account POST   /v1/accounts/:id/resume-subscription(.:format) api/v1/accounts/subscription#resume {:subdomain=>"api", :format=>"json"}
# cancel_subscription_v1_account POST   /v1/accounts/:id/cancel-subscription(.:format) api/v1/accounts/subscription#cancel {:subdomain=>"api", :format=>"json"}
#  renew_subscription_v1_account POST   /v1/accounts/:id/renew-subscription(.:format)  api/v1/accounts/subscription#renew {:subdomain=>"api", :format=>"json"}
#                    v1_accounts GET    /v1/accounts(.:format)                         api/v1/accounts#index {:subdomain=>"api", :format=>"json"}
#                                POST   /v1/accounts(.:format)                         api/v1/accounts#create {:subdomain=>"api", :format=>"json"}
#                     v1_account GET    /v1/accounts/:id(.:format)                     api/v1/accounts#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/accounts/:id(.:format)                     api/v1/accounts#update {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/accounts/:id(.:format)                     api/v1/accounts#update {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/accounts/:id(.:format)                     api/v1/accounts#destroy {:subdomain=>"api", :format=>"json"}
#                      v1_tokens POST   /v1/tokens(.:format)                           api/v1/tokens#generate {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/tokens(.:format)                           api/v1/tokens#regenerate_current {:subdomain=>"api", :format=>"json"}
#                             v1 PUT    /v1/tokens/:id(.:format)                       api/v1/tokens#regenerate {:subdomain=>"api", :format=>"json"}
#                                GET    /v1/tokens(.:format)                           api/v1/tokens#index {:subdomain=>"api", :format=>"json"}
#                                GET    /v1/tokens/:id(.:format)                       api/v1/tokens#show {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/tokens/:id(.:format)                       api/v1/tokens#revoke {:subdomain=>"api", :format=>"json"}
#                   v1_passwords POST   /v1/passwords(.:format)                        api/v1/passwords#reset_password {:subdomain=>"api", :format=>"json"}
#                     v1_profile GET    /v1/profile(.:format)                          api/v1/profiles#show {:subdomain=>"api", :format=>"json"}
#                        v1_keys GET    /v1/keys(.:format)                             api/v1/keys#index {:subdomain=>"api", :format=>"json"}
#                                POST   /v1/keys(.:format)                             api/v1/keys#create {:subdomain=>"api", :format=>"json"}
#                         v1_key GET    /v1/keys/:id(.:format)                         api/v1/keys#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/keys/:id(.:format)                         api/v1/keys#update {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/keys/:id(.:format)                         api/v1/keys#update {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/keys/:id(.:format)                         api/v1/keys#destroy {:subdomain=>"api", :format=>"json"}
#                    v1_machines GET    /v1/machines(.:format)                         api/v1/machines#index {:subdomain=>"api", :format=>"json"}
#                                POST   /v1/machines(.:format)                         api/v1/machines#create {:subdomain=>"api", :format=>"json"}
#                     v1_machine GET    /v1/machines/:id(.:format)                     api/v1/machines#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/machines/:id(.:format)                     api/v1/machines#update {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/machines/:id(.:format)                     api/v1/machines#update {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/machines/:id(.:format)                     api/v1/machines#destroy {:subdomain=>"api", :format=>"json"}
#           v1_webhook_endpoints GET    /v1/webhook-endpoints(.:format)                api/v1/webhook_endpoints#index {:subdomain=>"api", :format=>"json"}
#                                POST   /v1/webhook-endpoints(.:format)                api/v1/webhook_endpoints#create {:subdomain=>"api", :format=>"json"}
#            v1_webhook_endpoint GET    /v1/webhook-endpoints/:id(.:format)            api/v1/webhook_endpoints#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/webhook-endpoints/:id(.:format)            api/v1/webhook_endpoints#update {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/webhook-endpoints/:id(.:format)            api/v1/webhook_endpoints#update {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/webhook-endpoints/:id(.:format)            api/v1/webhook_endpoints#destroy {:subdomain=>"api", :format=>"json"}
#        update_password_v1_user POST   /v1/users/:id/update-password(.:format)        api/v1/users/password#update_password {:subdomain=>"api", :format=>"json"}
#         reset_password_v1_user POST   /v1/users/:id/reset-password(.:format)         api/v1/users/password#reset_password {:subdomain=>"api", :format=>"json"}
#                       v1_users GET    /v1/users(.:format)                            api/v1/users#index {:subdomain=>"api", :format=>"json"}
#                                POST   /v1/users(.:format)                            api/v1/users#create {:subdomain=>"api", :format=>"json"}
#                        v1_user GET    /v1/users/:id(.:format)                        api/v1/users#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/users/:id(.:format)                        api/v1/users#update {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/users/:id(.:format)                        api/v1/users#update {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/users/:id(.:format)                        api/v1/users#destroy {:subdomain=>"api", :format=>"json"}
#            validate_v1_license GET    /v1/licenses/:id/validate(.:format)            api/v1/licenses/validations#validate_by_id {:subdomain=>"api", :format=>"json"}
#              revoke_v1_license DELETE /v1/licenses/:id/revoke(.:format)              api/v1/licenses/permits#revoke {:subdomain=>"api", :format=>"json"}
#               renew_v1_license POST   /v1/licenses/:id/renew(.:format)               api/v1/licenses/permits#renew {:subdomain=>"api", :format=>"json"}
#       validate_key_v1_licenses POST   /v1/licenses/validate-key(.:format)            api/v1/licenses/validations#validate_by_key {:subdomain=>"api", :format=>"json"}
#                    v1_licenses GET    /v1/licenses(.:format)                         api/v1/licenses#index {:subdomain=>"api", :format=>"json"}
#                                POST   /v1/licenses(.:format)                         api/v1/licenses#create {:subdomain=>"api", :format=>"json"}
#                     v1_license GET    /v1/licenses/:id(.:format)                     api/v1/licenses#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/licenses/:id(.:format)                     api/v1/licenses#update {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/licenses/:id(.:format)                     api/v1/licenses#update {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/licenses/:id(.:format)                     api/v1/licenses#destroy {:subdomain=>"api", :format=>"json"}
#                 pool_v1_policy DELETE /v1/policies/:id/pool(.:format)                api/v1/policies/pool#pop {:subdomain=>"api", :format=>"json"}
#                    v1_policies GET    /v1/policies(.:format)                         api/v1/policies#index {:subdomain=>"api", :format=>"json"}
#                                POST   /v1/policies(.:format)                         api/v1/policies#create {:subdomain=>"api", :format=>"json"}
#                      v1_policy GET    /v1/policies/:id(.:format)                     api/v1/policies#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/policies/:id(.:format)                     api/v1/policies#update {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/policies/:id(.:format)                     api/v1/policies#update {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/policies/:id(.:format)                     api/v1/policies#destroy {:subdomain=>"api", :format=>"json"}
#              tokens_v1_product POST   /v1/products/:id/tokens(.:format)              api/v1/products/tokens#generate {:subdomain=>"api", :format=>"json"}
#                    v1_products GET    /v1/products(.:format)                         api/v1/products#index {:subdomain=>"api", :format=>"json"}
#                                POST   /v1/products(.:format)                         api/v1/products#create {:subdomain=>"api", :format=>"json"}
#                     v1_product GET    /v1/products/:id(.:format)                     api/v1/products#show {:subdomain=>"api", :format=>"json"}
#                                PATCH  /v1/products/:id(.:format)                     api/v1/products#update {:subdomain=>"api", :format=>"json"}
#                                PUT    /v1/products/:id(.:format)                     api/v1/products#update {:subdomain=>"api", :format=>"json"}
#                                DELETE /v1/products/:id(.:format)                     api/v1/products#destroy {:subdomain=>"api", :format=>"json"}
#         retry_v1_webhook_event POST   /v1/webhook-events/:id/retry(.:format)         api/v1/webhook_events/retries#retry {:subdomain=>"api", :format=>"json"}
#              v1_webhook_events GET    /v1/webhook-events(.:format)                   api/v1/webhook_events#index {:subdomain=>"api", :format=>"json"}
#               v1_webhook_event GET    /v1/webhook-events/:id(.:format)               api/v1/webhook_events#show {:subdomain=>"api", :format=>"json"}
#                                       /404(.:format)                                 errors#show {:code=>404}
#                                       /422(.:format)                                 errors#show {:code=>422}
#                                       /500(.:format)                                 errors#show {:code=>500}
#                           root GET    /                                              errors#show {:code=>404}
#
