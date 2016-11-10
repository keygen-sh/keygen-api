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
        get    "tokens",     to: "tokens#generate"
        post   "tokens",     to: "tokens#regenerate"
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

# == Route Map
#
#                           Prefix Verb   URI Pattern                                                  Controller#Action
#                        v1_stripe POST   /v1/stripe(.:format)                                         api/v1/stripe#receive_webhook {:format=>"json"}
#                         v1_plans GET    /v1/plans(.:format)                                          api/v1/plans#index {:format=>"json"}
#                          v1_plan GET    /v1/plans/:id(.:format)                                      api/v1/plans#show {:format=>"json"}
# v1_account_relationships_billing GET    /v1/accounts/:account_id/relationships/billing(.:format)     api/v1/accounts/relationships/billing#show {:format=>"json"}
#                                  POST   /v1/accounts/:account_id/relationships/billing(.:format)     api/v1/accounts/relationships/billing#update {:format=>"json"}
#    v1_account_relationships_plan POST   /v1/accounts/:account_id/relationships/plan(.:format)        api/v1/accounts/relationships/plan#update {:format=>"json"}
#         v1_account_actions_pause POST   /v1/accounts/:account_id/actions/pause(.:format)             api/v1/accounts/actions/subscription#pause {:format=>"json"}
#        v1_account_actions_resume POST   /v1/accounts/:account_id/actions/resume(.:format)            api/v1/accounts/actions/subscription#resume {:format=>"json"}
#        v1_account_actions_cancel POST   /v1/accounts/:account_id/actions/cancel(.:format)            api/v1/accounts/actions/subscription#cancel {:format=>"json"}
#         v1_account_actions_renew POST   /v1/accounts/:account_id/actions/renew(.:format)             api/v1/accounts/actions/subscription#renew {:format=>"json"}
#                      v1_accounts GET    /v1/accounts(.:format)                                       api/v1/accounts#index {:format=>"json"}
#                                  POST   /v1/accounts(.:format)                                       api/v1/accounts#create {:format=>"json"}
#                       v1_account GET    /v1/accounts/:id(.:format)                                   api/v1/accounts#show {:format=>"json"}
#                                  PATCH  /v1/accounts/:id(.:format)                                   api/v1/accounts#update {:format=>"json"}
#                                  PUT    /v1/accounts/:id(.:format)                                   api/v1/accounts#update {:format=>"json"}
#                                  DELETE /v1/accounts/:id(.:format)                                   api/v1/accounts#destroy {:format=>"json"}
#                        v1_tokens GET    /v1/tokens(.:format)                                         api/v1/tokens#generate {:format=>"json"}
#                                  POST   /v1/tokens(.:format)                                         api/v1/tokens#regenerate {:format=>"json"}
#                               v1 DELETE /v1/tokens/:id(.:format)                                     api/v1/tokens#revoke {:format=>"json"}
#                     v1_passwords POST   /v1/passwords(.:format)                                      api/v1/passwords#reset_password {:format=>"json"}
#                       v1_profile GET    /v1/profile(.:format)                                        api/v1/profiles#show {:format=>"json"}
#                          v1_keys GET    /v1/keys(.:format)                                           api/v1/keys#index {:format=>"json"}
#                                  POST   /v1/keys(.:format)                                           api/v1/keys#create {:format=>"json"}
#                           v1_key GET    /v1/keys/:id(.:format)                                       api/v1/keys#show {:format=>"json"}
#                                  PATCH  /v1/keys/:id(.:format)                                       api/v1/keys#update {:format=>"json"}
#                                  PUT    /v1/keys/:id(.:format)                                       api/v1/keys#update {:format=>"json"}
#                                  DELETE /v1/keys/:id(.:format)                                       api/v1/keys#destroy {:format=>"json"}
#                      v1_machines GET    /v1/machines(.:format)                                       api/v1/machines#index {:format=>"json"}
#                                  POST   /v1/machines(.:format)                                       api/v1/machines#create {:format=>"json"}
#                       v1_machine GET    /v1/machines/:id(.:format)                                   api/v1/machines#show {:format=>"json"}
#                                  PATCH  /v1/machines/:id(.:format)                                   api/v1/machines#update {:format=>"json"}
#                                  PUT    /v1/machines/:id(.:format)                                   api/v1/machines#update {:format=>"json"}
#                                  DELETE /v1/machines/:id(.:format)                                   api/v1/machines#destroy {:format=>"json"}
#             v1_webhook_endpoints GET    /v1/webhook-endpoints(.:format)                              api/v1/webhook_endpoints#index {:format=>"json"}
#                                  POST   /v1/webhook-endpoints(.:format)                              api/v1/webhook_endpoints#create {:format=>"json"}
#              v1_webhook_endpoint GET    /v1/webhook-endpoints/:id(.:format)                          api/v1/webhook_endpoints#show {:format=>"json"}
#                                  PATCH  /v1/webhook-endpoints/:id(.:format)                          api/v1/webhook_endpoints#update {:format=>"json"}
#                                  PUT    /v1/webhook-endpoints/:id(.:format)                          api/v1/webhook_endpoints#update {:format=>"json"}
#                                  DELETE /v1/webhook-endpoints/:id(.:format)                          api/v1/webhook_endpoints#destroy {:format=>"json"}
#  v1_user_actions_update_password POST   /v1/users/:user_id/actions/update-password(.:format)         api/v1/users/actions/password#update_password {:format=>"json"}
#   v1_user_actions_reset_password POST   /v1/users/:user_id/actions/reset-password(.:format)          api/v1/users/actions/password#reset_password {:format=>"json"}
#                         v1_users GET    /v1/users(.:format)                                          api/v1/users#index {:format=>"json"}
#                                  POST   /v1/users(.:format)                                          api/v1/users#create {:format=>"json"}
#                          v1_user GET    /v1/users/:id(.:format)                                      api/v1/users#show {:format=>"json"}
#                                  PATCH  /v1/users/:id(.:format)                                      api/v1/users#update {:format=>"json"}
#                                  PUT    /v1/users/:id(.:format)                                      api/v1/users#update {:format=>"json"}
#                                  DELETE /v1/users/:id(.:format)                                      api/v1/users#destroy {:format=>"json"}
#      v1_license_actions_validate GET    /v1/licenses/:license_id/actions/validate(.:format)          api/v1/licenses/actions/permits#validate {:format=>"json"}
#        v1_license_actions_revoke POST   /v1/licenses/:license_id/actions/revoke(.:format)            api/v1/licenses/actions/permits#revoke {:format=>"json"}
#         v1_license_actions_renew POST   /v1/licenses/:license_id/actions/renew(.:format)             api/v1/licenses/actions/permits#renew {:format=>"json"}
#                      v1_licenses GET    /v1/licenses(.:format)                                       api/v1/licenses#index {:format=>"json"}
#                                  POST   /v1/licenses(.:format)                                       api/v1/licenses#create {:format=>"json"}
#                       v1_license GET    /v1/licenses/:id(.:format)                                   api/v1/licenses#show {:format=>"json"}
#                                  PATCH  /v1/licenses/:id(.:format)                                   api/v1/licenses#update {:format=>"json"}
#                                  PUT    /v1/licenses/:id(.:format)                                   api/v1/licenses#update {:format=>"json"}
#                                  DELETE /v1/licenses/:id(.:format)                                   api/v1/licenses#destroy {:format=>"json"}
#     v1_policy_relationships_pool DELETE /v1/policies/:policy_id/relationships/pool(.:format)         api/v1/policies/relationships/pool#pop {:format=>"json"}
#                      v1_policies GET    /v1/policies(.:format)                                       api/v1/policies#index {:format=>"json"}
#                                  POST   /v1/policies(.:format)                                       api/v1/policies#create {:format=>"json"}
#                        v1_policy GET    /v1/policies/:id(.:format)                                   api/v1/policies#show {:format=>"json"}
#                                  PATCH  /v1/policies/:id(.:format)                                   api/v1/policies#update {:format=>"json"}
#                                  PUT    /v1/policies/:id(.:format)                                   api/v1/policies#update {:format=>"json"}
#                                  DELETE /v1/policies/:id(.:format)                                   api/v1/policies#destroy {:format=>"json"}
#  v1_product_relationships_tokens GET    /v1/products/:product_id/relationships/tokens(.:format)      api/v1/products/relationships/tokens#generate {:format=>"json"}
#                      v1_products GET    /v1/products(.:format)                                       api/v1/products#index {:format=>"json"}
#                                  POST   /v1/products(.:format)                                       api/v1/products#create {:format=>"json"}
#                       v1_product GET    /v1/products/:id(.:format)                                   api/v1/products#show {:format=>"json"}
#                                  PATCH  /v1/products/:id(.:format)                                   api/v1/products#update {:format=>"json"}
#                                  PUT    /v1/products/:id(.:format)                                   api/v1/products#update {:format=>"json"}
#                                  DELETE /v1/products/:id(.:format)                                   api/v1/products#destroy {:format=>"json"}
#   v1_webhook_event_actions_retry POST   /v1/webhook-events/:webhook_event_id/actions/retry(.:format) api/v1/webhook_events/actions/retries#retry {:format=>"json"}
#                v1_webhook_events GET    /v1/webhook-events(.:format)                                 api/v1/webhook_events#index {:format=>"json"}
#                 v1_webhook_event GET    /v1/webhook-events/:id(.:format)                             api/v1/webhook_events#show {:format=>"json"}
#                                         /404(.:format)                                               errors#show {:code=>404}
#                                         /422(.:format)                                               errors#show {:code=>422}
#                                         /500(.:format)                                               errors#show {:code=>500}
#                             root GET    /                                                            errors#show {:code=>404}
#
