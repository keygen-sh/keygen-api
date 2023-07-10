# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq_unique_jobs/web'

Rails.application.routes.draw do
  domain_constraints =
    if !Rails.env.development?
      {
        domain: ENV.fetch('KEYGEN_DOMAIN') {
          # Get host without subdomains if domain is not explicitly set
          host    = ENV.fetch('KEYGEN_HOST')
          domains = host.downcase.strip.split('.')[-2..-1]
          next if
            domains.blank?

          domains.join('.')
        },
      }
    else
      {}
    end

  subdomain_constraints =
    if !Rails.env.development?
      {
        subdomain: ENV.fetch('KEYGEN_SUBDOMAIN') {
          # Get subdomain when subdomain is not explicitly set
          host       = ENV.fetch('KEYGEN_HOST')
          subdomains = host.downcase.strip.split('.')[0..-3]
          next if
            subdomains.blank?

          subdomains.join('.')
        },
      }
    else
      { subdomain: 'api' }
    end

  mount Sidekiq::Web, at: '/-/sidekiq'

  namespace '-' do
    post 'csp-reports', to: proc { |env|
      bytesize = env['rack.input'].size
      next [422, {}, []] if bytesize > 10.kilobytes

      payload = env['rack.input'].read
      env['rack.input'].rewind

      Rails.logger.warn "[csp-reports] CSP violation: size=#{bytesize} payload=#{payload}"

      [202, {}, []]
    }
  end

  if Keygen.multiplayer?
    scope module: :bin, constraints: { subdomain: %w[bin get], **domain_constraints, format: :jsonapi } do
      version_constraint '<=1.0' do
        scope module: :v1x0 do
          get ':account_id',     constraints: { account_id: /[^\/]*/ },           to: 'release_artifacts#index', as: :bin_artifacts
          get ':account_id/:id', constraints: { account_id: /[^\/]*/, id: /.*/ }, to: 'release_artifacts#show',  as: :bin_artifact
        end
      end

      version_constraint '>=1.1' do
        get ':account_id/:release_id',     constraints: { account_id: /[^\/]+/, release_id: /[^\/]+/ },           to: 'release_artifacts#index'
        get ':account_id/:release_id/:id', constraints: { account_id: /[^\/]+/, release_id: /[^\/]+/, id: /.*/ }, to: 'release_artifacts#show'
      end
    end

    scope module: :stdout, constraints: { subdomain: %w[stdout], **domain_constraints, format: :jsonapi } do
      get 'unsub/:ciphertext', constraints: { ciphertext: /.*/ }, to: 'subscribers#unsubscribe', as: :stdout_unsubscribe
    end
  end

  concern :v1 do
    get :ping, to: 'health#general_ping'

    scope constraints: FormatConstraint.new(format: %i[jsonapi json octet_stream]), defaults: { format: :jsonapi } do
      post :passwords, to: 'passwords#reset'
      get  :profile,   to: 'profiles#show'
      get  :me,        to: 'profiles#me'

      resources :tokens, only: %i[index show] do
        collection do
          post '/', to: 'tokens#generate'

          # FIXME(ezekg) Deprecate this route
          put  '/', to: 'tokens#regenerate_current'
        end

        member do
          put    '/', to: 'tokens#regenerate'
          delete '/', to: 'tokens#revoke'
        end
      end

      resources :keys do
        scope module: 'keys/relationships' do
          resource :product, only: %i[show]
          resource :policy,  only: %i[show]
        end
      end

      # NOTE(ezekg) By default, Rails does not allow dots inside our routes, but
      #             we want to support dots since our machines are queryable by
      #             their fingerprint attr, which can be an arbitrary string.
      resources :machines, constraints: { id: /[^\/]*/ } do
        scope module: 'machines/relationships' do
          resources :machine_processes, only: %i[index show], path: 'processes'

          resource :product, only: %i[show]
          resource :group,   only: %i[show update]
          resource :license, only: %i[show]
          resource :user,    only: %i[show]
        end

        member do
          scope :actions, module: 'machines/actions' do
            post :reset_heartbeat, path: 'reset-heartbeat', to: 'heartbeats#reset'
            post :ping_heartbeat,  path: 'ping-heartbeat',  to: 'heartbeats#ping'
            post :reset,                                    to: 'heartbeats#reset'
            post :ping,                                     to: 'heartbeats#ping'
            post :check_out,       path: 'check-out',       to: 'checkouts#create'
            get :check_out,        path: 'check-out',       to: 'checkouts#show', defaults: { format: :octet_stream }

            scope module: :v1x0 do
              post :generate_offline_proof, path: 'generate-offline-proof', to: 'proofs#create'
            end
          end
        end
      end

      resources :machine_processes, path: 'processes' do
        scope module: 'machine_processes/relationships' do
          resource :product, only: %i[show]
          resource :license, only: %i[show]
          resource :machine, only: %i[show]
        end

        member do
          scope :actions, module: 'machine_processes/actions' do
            post :ping, to: 'heartbeats#ping'
          end
        end
      end

      # NOTE(ezekg) Users are queryable by email attr.
      resources :users, constraints: { id: /[^\/]*/ } do
        scope module: 'users/relationships' do
          resources :second_factors, path: 'second-factors', only: %i[index show create update destroy]
          resources :products,                               only: %i[index show]
          resources :licenses,                               only: %i[index show]
          resources :machines,                               only: %i[index show]
          resources :tokens,                                 only: %i[index show create]

          resource :group, only: %i[show update]
        end

        member do
          scope :actions, module: 'users/actions' do
            post :update_password, path: 'update-password', to: 'password#update'
            post :reset_password,  path: 'reset-password',  to: 'password#reset'
            post :ban,                                      to: 'bans#ban'
            post :unban,                                    to: 'bans#unban'
          end
        end
      end

      # NOTE(ezekg) Licenses are queryable by their key attr, which can be an
      #             arbitrary string.
      resources :licenses, constraints: { id: /[^\/]*/ } do
        scope module: 'licenses/relationships' do
          resources :machines, only: %i[index show]
          resources :tokens,   only: %i[index show create]

          resource :product, only: %i[show]
          resource :policy,  only: %i[show update]
          resource :group,   only: %i[show update]
          resource :user,    only: %i[show update]

          resources :entitlements, only: %i[index show] do
            collection do
              post '/',   to: 'entitlements#attach', as: :attach
              delete '/', to: 'entitlements#detach', as: :detach
            end
          end
        end

        member do
          scope :actions, module: 'licenses/actions' do
            get :validate,                                  to: 'validations#quick_validate_by_id'
            post :validate,                                 to: 'validations#validate_by_id'
            delete :revoke,                                 to: 'permits#revoke'
            post :renew,                                    to: 'permits#renew'
            post :suspend,                                  to: 'permits#suspend'
            post :reinstate,                                to: 'permits#reinstate'
            post :check_in,        path: 'check-in',        to: 'permits#check_in'
            post :increment_usage, path: 'increment-usage', to: 'uses#increment'
            post :decrement_usage, path: 'decrement-usage', to: 'uses#decrement'
            post :reset_usage,     path: 'reset-usage',     to: 'uses#reset'
            post :check_out,       path: 'check-out',       to: 'checkouts#create'
            get :check_out,        path: 'check-out',       to: 'checkouts#show', defaults: { format: :octet_stream }
          end
        end

        collection do
          scope :actions, module: 'licenses/actions' do
            post :validate_key, path: 'validate-key', to: 'validations#validate_by_key'
          end
        end
      end

      resources :policies do
        scope module: 'policies/relationships' do
          resources :licenses, only: %i[index show]
          resource :product,   only: %i[show]

          resources :pool, only: %i[index show], as: :keys do
            collection do
              delete '/', to: 'pool#pop', as: :pop
            end
          end

          resources :entitlements, only: %i[index show] do
            collection do
              post '/',   to: 'entitlements#attach', as: :attach
              delete '/', to: 'entitlements#detach', as: :detach
            end
          end
        end
      end

      resources :products do
        scope module: 'products/relationships' do
          resources :policies,          only: %i[index show]
          resources :licenses,          only: %i[index show]
          resources :machines,          only: %i[index show]
          resources :tokens,            only: %i[index show create]
          resources :users,             only: %i[index show]
          resources :releases,          only: %i[index show],                    constraints: { id: /[^\/]*/ }
          resources :release_artifacts, only: %i[index show], path: 'artifacts', constraints: { id: /.*/ }
          resources :release_platforms, only: %i[index show], path: 'platforms'
          resources :release_arches,    only: %i[index show], path: 'arches'
          resources :release_channels,  only: %i[index show], path: 'channels'
        end
      end

      resources :releases, constraints: { id: /[^\/]*/ } do
        version_constraint '<=1.0' do
          member do
            scope :actions, module: 'releases/actions' do
              scope module: :v1x0 do
                get :upgrade, to: 'upgrades#check_for_upgrade_by_id'
              end
            end
          end

          collection do
            put '/', to: 'releases#create', as: :upsert

            scope :actions, module: 'releases/actions' do
              scope module: :v1x0 do
                # FIXME(ezekg) This needs to take precedence over the upgrade relationship,
                #              otherwise the relationship tries to match "actions" as a
                #              release ID when hitting the root /actions/upgrade.
                get :upgrade, to: 'upgrades#check_for_upgrade_by_query'
              end
            end
          end
        end

        scope module: 'releases/relationships' do
          resources :release_entitlement_constraints, only: %i[index show], path: 'constraints' do
            collection do
              post '/',   to: 'release_entitlement_constraints#attach', as: :attach
              delete '/', to: 'release_entitlement_constraints#detach', as: :detach
            end
          end

          resources :entitlements,      only: %i[index show]
          resources :release_artifacts, only: %i[index show], path: 'artifacts'

          resource :upgrade, only: %i[show]
          resource :product, only: %i[show]

          version_constraint '<=1.0' do
            scope module: :v1x0 do
              resource :release_artifact, only: %i[show destroy], path: 'artifact', as: :v1_0_release_artifact do
                put :create
              end
            end
          end
        end

        member do
          scope :actions, module: 'releases/actions' do
            post :publish, to: 'publishings#publish'
            post :yank, to: 'publishings#yank'
          end
        end
      end

      resources :release_artifacts,                       path: 'artifacts', constraints: { id: /.*/, format: /.*/ }
      resources :release_platforms, only: %i[index show], path: 'platforms'
      resources :release_arches,    only: %i[index show], path: 'arches'
      resources :release_channels,  only: %i[index show], path: 'channels'

      resources :entitlements

      resources :groups do
        scope module: 'groups/relationships' do
          resources :users,    only: %i[index show]
          resources :licenses, only: %i[index show]
          resources :machines, only: %i[index show]

          resources :group_owners, only: %i[index show], path: 'owners' do
            collection do
              post '/',   to: 'group_owners#attach', as: :attach
              delete '/', to: 'group_owners#detach', as: :detach
            end
          end
        end
      end

      resources :webhook_endpoints, path: 'webhook-endpoints'

      resources :webhook_events, path: 'webhook-events', only: %i[index show destroy] do
        member do
          scope :actions, module: 'webhook_events/actions' do
            post :retry, to: 'retries#retry'
          end
        end
      end

      ee do
        resources :request_logs, path: 'request-logs', only: %i[index show]  do
          collection do
            scope :actions, module: 'request_logs/actions' do
              get :count, to: 'counts#count'
            end
          end
        end

        resources :environments do
          scope module: 'environments/relationships' do
            resources :tokens, only: %i[index show create]
          end
        end

        resources :event_logs, path: 'event-logs', only: %i[index show]
      end

      resources :metrics, only: %i[index show] do
        collection do
          scope :actions, module: 'metrics/actions' do
            get :count, to: 'counts#count'
          end
        end
      end

      resources :analytics, only: [] do
        collection do
          scope :actions, module: 'analytics/actions' do
            get :top_licenses_by_volume, path: 'top-licenses-by-volume', to: 'counts#top_licenses_by_volume'
            get :top_urls_by_volume,     path: 'top-urls-by-volume',     to: 'counts#top_urls_by_volume'
            get :top_ips_by_volume,      path: 'top-ips-by-volume',      to: 'counts#top_ips_by_volume'
            get :count,                                                  to: 'counts#count'
          end
        end
      end

      post :search, to: 'searches#search'
    end

    namespace :release_packages, path: 'packages' do
      scope :pypi, module: :pypi, constraints: FormatConstraint.new(format: :html), defaults: { format: :html } do
        get 'simple/:id', to: 'simple#index', as: :pypi_packages
      end
    end
  end

  scope module: :api do
    namespace :v1 do
      constraints **domain_constraints, **subdomain_constraints do
        if Keygen.multiplayer?
          post :stripe, to: 'stripe#receive_webhook'

          # Pricing
          scope constraints: FormatConstraint.new(format: %i[jsonapi json]), defaults: { format: :jsonapi } do
            resources :plans, only: %i[index show]
          end
        end

        # Health checks
        scope :health do
          get '/',       to: 'health#general_health'
          get :webhooks, to: 'health#webhook_health'
        end

        # Recover
        scope constraints: FormatConstraint.new(format: %i[jsonapi json]), defaults: { format: :jsonapi } do
          post :recover, to: 'recoveries#recover'

          # Account
          case
          when Keygen.singleplayer?
            resources :accounts, param: :account_id, only: %i[show update destroy]
          when Keygen.multiplayer?
            resources :accounts, param: :account_id, only: %i[show create update destroy]
          end
        end

        # Routes with :account_id scope i.e. multiplayer mode. Most of these
        # routes are also available in singleplayer mode for compatiblity.
        scope 'accounts/:account_id', as: :account do
          if Keygen.multiplayer?
            scope constraints: FormatConstraint.new(format: %i[jsonapi json]), defaults: { format: :jsonapi } do
              scope module: 'accounts/relationships' do
                resource :billing, only: %i[show update]
                resource :plan,    only: %i[show update]
              end

              scope :actions, module: 'accounts/actions' do
                post :manage_subscription, path: 'manage-subscription', to: 'subscription#manage'
                post :pause_subscription,  path: 'pause-subscription',  to: 'subscription#pause'
                post :resume_subscription, path: 'resume-subscription', to: 'subscription#resume'
                post :cancel_subscription, path: 'cancel-subscription', to: 'subscription#cancel'
                post :renew_subscription,  path: 'renew-subscription',  to: 'subscription#renew'
              end
            end
          end

          concerns :v1
        end
      end

      # Routes without :account_id scope i.e. singleplayer mode. This is
      # also used for CNAME routing (under multiplayer mode).
      concerns :v1
    end
  end

  %w[500 503].each do |code|
    match code, to: 'errors#show', code: code.to_i, via: :all
  end

  match '*unmatched_route', to: 'errors#show', code: 404, via: :all
  root to: 'errors#show', code: 404, via: :all
end
