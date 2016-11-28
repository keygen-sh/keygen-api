Rails.application.routes.draw do
  scope module: "api" do
    namespace "v1", constraints: { subdomain: "api", format: "json" } do
      post "stripe", to: "stripe#receive_webhook"

      resources "plans", only: [:index, :show]

      resources "accounts" do
        scope module: "accounts" do
          namespace "relationships" do
            get "billing", to: "billing#show"
            patch "billing", to: "billing#update"
            put "plan", to: "plan#update"
          end
          namespace "actions" do
            post "pause", to: "subscription#pause"
            post "resume", to: "subscription#resume"
            post "cancel", to: "subscription#cancel"
            post "renew", to: "subscription#renew"
          end
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
            get "validate", to: "validations#validate_by_id"
            delete "revoke", to: "permits#revoke"
            post "renew", to: "permits#renew"
          end
        end
      end

      namespace "licenses" do
        namespace "actions" do
          post "validate-key", to: "validations#validate_by_key"
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
            post "tokens", to: "tokens#generate"
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
# v1_account_relationships_billing GET    /v1/accounts/:account_id/relationships/billing(.:format)     api/v1/accounts/relationships/billing#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:account_id/relationships/billing(.:format)     api/v1/accounts/relationships/billing#update {:subdomain=>"api", :format=>"json"}
#    v1_account_relationships_plan PUT    /v1/accounts/:account_id/relationships/plan(.:format)        api/v1/accounts/relationships/plan#update {:subdomain=>"api", :format=>"json"}
#         v1_account_actions_pause POST   /v1/accounts/:account_id/actions/pause(.:format)             api/v1/accounts/actions/subscription#pause {:subdomain=>"api", :format=>"json"}
#        v1_account_actions_resume POST   /v1/accounts/:account_id/actions/resume(.:format)            api/v1/accounts/actions/subscription#resume {:subdomain=>"api", :format=>"json"}
#        v1_account_actions_cancel POST   /v1/accounts/:account_id/actions/cancel(.:format)            api/v1/accounts/actions/subscription#cancel {:subdomain=>"api", :format=>"json"}
#         v1_account_actions_renew POST   /v1/accounts/:account_id/actions/renew(.:format)             api/v1/accounts/actions/subscription#renew {:subdomain=>"api", :format=>"json"}
#                      v1_accounts GET    /v1/accounts(.:format)                                       api/v1/accounts#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/accounts(.:format)                                       api/v1/accounts#create {:subdomain=>"api", :format=>"json"}
#                       v1_account GET    /v1/accounts/:id(.:format)                                   api/v1/accounts#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/accounts/:id(.:format)                                   api/v1/accounts#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/accounts/:id(.:format)                                   api/v1/accounts#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/accounts/:id(.:format)                                   api/v1/accounts#destroy {:subdomain=>"api", :format=>"json"}
#                        v1_tokens POST   /v1/tokens(.:format)                                         api/v1/tokens#generate {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/tokens(.:format)                                         api/v1/tokens#regenerate_current {:subdomain=>"api", :format=>"json"}
#                               v1 PUT    /v1/tokens/:id(.:format)                                     api/v1/tokens#regenerate {:subdomain=>"api", :format=>"json"}
#                                  GET    /v1/tokens(.:format)                                         api/v1/tokens#index {:subdomain=>"api", :format=>"json"}
#                                  GET    /v1/tokens/:id(.:format)                                     api/v1/tokens#show {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/tokens/:id(.:format)                                     api/v1/tokens#revoke {:subdomain=>"api", :format=>"json"}
#                     v1_passwords POST   /v1/passwords(.:format)                                      api/v1/passwords#reset_password {:subdomain=>"api", :format=>"json"}
#                       v1_profile GET    /v1/profile(.:format)                                        api/v1/profiles#show {:subdomain=>"api", :format=>"json"}
#                          v1_keys GET    /v1/keys(.:format)                                           api/v1/keys#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/keys(.:format)                                           api/v1/keys#create {:subdomain=>"api", :format=>"json"}
#                           v1_key GET    /v1/keys/:id(.:format)                                       api/v1/keys#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/keys/:id(.:format)                                       api/v1/keys#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/keys/:id(.:format)                                       api/v1/keys#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/keys/:id(.:format)                                       api/v1/keys#destroy {:subdomain=>"api", :format=>"json"}
#                      v1_machines GET    /v1/machines(.:format)                                       api/v1/machines#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/machines(.:format)                                       api/v1/machines#create {:subdomain=>"api", :format=>"json"}
#                       v1_machine GET    /v1/machines/:id(.:format)                                   api/v1/machines#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/machines/:id(.:format)                                   api/v1/machines#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/machines/:id(.:format)                                   api/v1/machines#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/machines/:id(.:format)                                   api/v1/machines#destroy {:subdomain=>"api", :format=>"json"}
#             v1_webhook_endpoints GET    /v1/webhook-endpoints(.:format)                              api/v1/webhook_endpoints#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/webhook-endpoints(.:format)                              api/v1/webhook_endpoints#create {:subdomain=>"api", :format=>"json"}
#              v1_webhook_endpoint GET    /v1/webhook-endpoints/:id(.:format)                          api/v1/webhook_endpoints#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/webhook-endpoints/:id(.:format)                          api/v1/webhook_endpoints#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/webhook-endpoints/:id(.:format)                          api/v1/webhook_endpoints#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/webhook-endpoints/:id(.:format)                          api/v1/webhook_endpoints#destroy {:subdomain=>"api", :format=>"json"}
#  v1_user_actions_update_password POST   /v1/users/:user_id/actions/update-password(.:format)         api/v1/users/actions/password#update_password {:subdomain=>"api", :format=>"json"}
#   v1_user_actions_reset_password POST   /v1/users/:user_id/actions/reset-password(.:format)          api/v1/users/actions/password#reset_password {:subdomain=>"api", :format=>"json"}
#                         v1_users GET    /v1/users(.:format)                                          api/v1/users#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/users(.:format)                                          api/v1/users#create {:subdomain=>"api", :format=>"json"}
#                          v1_user GET    /v1/users/:id(.:format)                                      api/v1/users#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/users/:id(.:format)                                      api/v1/users#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/users/:id(.:format)                                      api/v1/users#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/users/:id(.:format)                                      api/v1/users#destroy {:subdomain=>"api", :format=>"json"}
#      v1_license_actions_validate GET    /v1/licenses/:license_id/actions/validate(.:format)          api/v1/licenses/actions/validations#validate_by_id {:subdomain=>"api", :format=>"json"}
#        v1_license_actions_revoke DELETE /v1/licenses/:license_id/actions/revoke(.:format)            api/v1/licenses/actions/permits#revoke {:subdomain=>"api", :format=>"json"}
#         v1_license_actions_renew POST   /v1/licenses/:license_id/actions/renew(.:format)             api/v1/licenses/actions/permits#renew {:subdomain=>"api", :format=>"json"}
#                      v1_licenses GET    /v1/licenses(.:format)                                       api/v1/licenses#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/licenses(.:format)                                       api/v1/licenses#create {:subdomain=>"api", :format=>"json"}
#                       v1_license GET    /v1/licenses/:id(.:format)                                   api/v1/licenses#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/licenses/:id(.:format)                                   api/v1/licenses#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/licenses/:id(.:format)                                   api/v1/licenses#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/licenses/:id(.:format)                                   api/v1/licenses#destroy {:subdomain=>"api", :format=>"json"}
# v1_licenses_actions_validate_key POST   /v1/licenses/actions/validate-key(.:format)                  api/v1/licenses/actions/validations#validate_by_key {:subdomain=>"api", :format=>"json"}
#     v1_policy_relationships_pool DELETE /v1/policies/:policy_id/relationships/pool(.:format)         api/v1/policies/relationships/pool#pop {:subdomain=>"api", :format=>"json"}
#                      v1_policies GET    /v1/policies(.:format)                                       api/v1/policies#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/policies(.:format)                                       api/v1/policies#create {:subdomain=>"api", :format=>"json"}
#                        v1_policy GET    /v1/policies/:id(.:format)                                   api/v1/policies#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/policies/:id(.:format)                                   api/v1/policies#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/policies/:id(.:format)                                   api/v1/policies#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/policies/:id(.:format)                                   api/v1/policies#destroy {:subdomain=>"api", :format=>"json"}
#  v1_product_relationships_tokens POST   /v1/products/:product_id/relationships/tokens(.:format)      api/v1/products/relationships/tokens#generate {:subdomain=>"api", :format=>"json"}
#                      v1_products GET    /v1/products(.:format)                                       api/v1/products#index {:subdomain=>"api", :format=>"json"}
#                                  POST   /v1/products(.:format)                                       api/v1/products#create {:subdomain=>"api", :format=>"json"}
#                       v1_product GET    /v1/products/:id(.:format)                                   api/v1/products#show {:subdomain=>"api", :format=>"json"}
#                                  PATCH  /v1/products/:id(.:format)                                   api/v1/products#update {:subdomain=>"api", :format=>"json"}
#                                  PUT    /v1/products/:id(.:format)                                   api/v1/products#update {:subdomain=>"api", :format=>"json"}
#                                  DELETE /v1/products/:id(.:format)                                   api/v1/products#destroy {:subdomain=>"api", :format=>"json"}
#   v1_webhook_event_actions_retry POST   /v1/webhook-events/:webhook_event_id/actions/retry(.:format) api/v1/webhook_events/actions/retries#retry {:subdomain=>"api", :format=>"json"}
#                v1_webhook_events GET    /v1/webhook-events(.:format)                                 api/v1/webhook_events#index {:subdomain=>"api", :format=>"json"}
#                 v1_webhook_event GET    /v1/webhook-events/:id(.:format)                             api/v1/webhook_events#show {:subdomain=>"api", :format=>"json"}
#                                         /404(.:format)                                               errors#show {:code=>404}
#                                         /422(.:format)                                               errors#show {:code=>422}
#                                         /500(.:format)                                               errors#show {:code=>500}
#                             root GET    /                                                            errors#show {:code=>404}
#
