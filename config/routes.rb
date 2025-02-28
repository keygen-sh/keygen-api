# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  if ENV.key?('SIDEKIQ_WEB_USER') && ENV.key?('SIDEKIQ_WEB_PASSWORD')
    mount Sidekiq::Web, at: '/-/sidekiq'
  end

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

  concern :pypi do
    # see: https://peps.python.org/pep-0503/
    scope module: :pypi, constraints: MimeTypeConstraint.new(:html, raise_on_no_match: true), defaults: { format: :html } do
      get 'simple/',          to: 'simple#index', as: :pypi_simple_packages, trailing_slash: true
      get 'simple/:package/', to: 'simple#show',  as: :pypi_simple_package,  trailing_slash: true
    end
  end

  concern :tauri do
    # see: https://v2.tauri.app/plugin/updater/#dynamic-update-server
    scope module: :tauri, constraints: MimeTypeConstraint.new(:binary, :json, raise_on_no_match: true), defaults: { format: :json } do
      get ':package', to: 'upgrades#show'
    end
  end

  concern :raw do
    scope module: :raw, defaults: { format: :binary } do
      get ':product(/@:package)/:release/:artifact', to: 'release_artifacts#show', constraints: {
        product: /[^\/]*/ ,
        package: /[^\/]*/ ,
        release: /[^\/]*/ ,
        artifact: /.*/,
      }
    end
  end

  concern :rubygems do
    # see: https://github.com/rubygems/guides/blob/e0a52c4ce6a6cbfb37886c52f2a8ac1c4b9fec77/rubygems-org-compact-index-api.md
    scope module: :rubygems, constraints: MimeTypeConstraint.new(:text, raise_on_no_match: true), defaults: { format: :text } do
      get 'versions',  to: 'compact_index#versions', as: :rubygems_compact_versions
      get 'info/:gem', to: 'compact_index#info',     as: :rubygems_compact_info
      get 'names',     to: 'compact_index#names',    as: :rubygems_compact_names

      # signals compact index support to rubygems
      root via: :head, to: 'compact_index#ping', as: :rubygems_compact_ping
    end

    scope module: :rubygems, defaults: { format: :binary } do
      get 'quick/Marshal.4.8/:gem.gemspec.rz', to: 'specs#quick_gemspec',    as: :rubygems_quick_gemspec,    constraints: { gem: /[^\/]+/ }
      get 'specs.4.8.gz',                      to: 'specs#specs',            as: :rubygems_specs
      get 'latest_specs.4.8.gz',               to: 'specs#latest_specs',     as: :rubygems_latest_specs
      get 'prerelease_specs.4.8.gz',           to: 'specs#prerelease_specs', as: :rubygems_prerelease_specs
      get 'gems/:gem.gem',                     to: 'gems#show',              as: :rubygems_gem,              constraints: { gem: /[^\/]+/ }
    end
  end

  concern :npm do
    # see: https://github.com/npm/registry/blob/ae49abf1bac0ec1a3f3f1fceea1cca6fe2dc00e1/docs/responses/package-metadata.md
    scope module: :npm, constraints: MimeTypeConstraint.new(:json, raise_on_no_match: true), defaults: { format: :json } do
      get ':package', to: 'package_metadata#show', as: :npm_package_metadata, constraints: {
        # see: https://docs.npmjs.com/cli/v9/configuring-npm/package-json#name
        package: /(?:@([a-z0-9][a-z0-9-]*[a-z0-9])(\/|%2F))?([a-z0-9][a-z0-9._-]*[a-z0-9])/,
      }
    end

    # ignore these npm requests entirely for now e.g. POST /-/npm/v1/security/advisories/bulk
    scope module: :npm, defaults: { format: :binary } do
      match '/-/npm/*wildcard', via: :all, to: -> env { [410, {}, []] }
    end
  end

  concern :oci do
    # NOTE(ezekg) /v2 namespace is handled outside of this because docker wants it to always be at the root...
    scope module: :oci, defaults: { format: :json } do
      # see: https://github.com/opencontainers/distribution-spec/blob/main/spec.md#pulling-manifests
      match ':package/manifests/:reference', via: %i[head get], to: 'manifests#show', as: :oci_manifest, constraints: {
        package: /[^\/]*/,
        reference: /[^\/]*/,
      }

      # see: https://github.com/opencontainers/distribution-spec/blob/main/spec.md#pulling-blobs
      match ':package/blobs/:digest', via: %i[head get], to: 'blobs#show', as: :oci_blob, constraints: {
        package: /[^\/]*/,
        digest: /[^\/]*/,
      }

      # see: https://github.com/opencontainers/distribution-spec/blob/main/spec.md#listing-tags
      get ':package/tags/list', to: 'tags#index', as: :oci_tags, constraints: {
        package: /[^\/]*/,
      }

      # ignore other requests entirely for now e.g. GET /v2/:namespace/referrers/:digest
      match '*wildcard', via: :all, to: -> env { [405, {}, []] }
    end
  end

  concern :v1 do
    get :ping, to: 'health#general_ping'

    scope constraints: MimeTypeConstraint.new(:jsonapi, :json, :binary, raise_on_no_match: true), defaults: { format: :jsonapi } do
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
          resources :machine_components, only: %i[index show], path: 'components'
          resources :machine_processes,  only: %i[index show], path: 'processes'

          resource :product, only: %i[show]
          resource :group,   only: %i[show update]
          resource :license, only: %i[show]
          resource :owner,   only: %i[show update]

          scope module: :v1x5 do
            resource :user, only: %i[show], as: :v1_5_user
          end
        end

        member do
          scope :actions, module: 'machines/actions' do
            post :reset_heartbeat, path: 'reset-heartbeat', to: 'heartbeats#reset'
            post :ping_heartbeat,  path: 'ping-heartbeat',  to: 'heartbeats#ping'
            post :reset,                                    to: 'heartbeats#reset'
            post :ping,                                     to: 'heartbeats#ping'
            post :check_out,       path: 'check-out',       to: 'checkouts#create'
            get :check_out,        path: 'check-out',       to: 'checkouts#show', defaults: { format: :binary }

            scope module: :v1x0 do
              post :generate_offline_proof, path: 'generate-offline-proof', to: 'proofs#create'
            end
          end
        end
      end

      resources :machine_components, path: 'components' do
        scope module: 'machine_components/relationships' do
          resource :product, only: %i[show]
          resource :license, only: %i[show]
          resource :machine, only: %i[show]
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
          resource :owner,   only: %i[show update]

          resources :entitlements, only: %i[index show] do
            collection do
              post '/',   to: 'entitlements#attach', as: :attach
              delete '/', to: 'entitlements#detach', as: :detach
            end
          end

          resources :users, only: %i[index show] do
            collection do
              post '/',   to: 'users#attach', as: :attach
              delete '/', to: 'users#detach', as: :detach
            end
          end

          scope module: :v1x5 do
            resource :user, only: %i[show update], as: :v1_5_user
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
            get :check_out,        path: 'check-out',       to: 'checkouts#show', defaults: { format: :binary }
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
          resources :release_packages,  only: %i[index show], path: 'packages'
          resources :release_artifacts, only: %i[index show], path: 'artifacts', constraints: { id: /.*/ }
          resources :release_platforms, only: %i[index show], path: 'platforms'
          resources :release_arches,    only: %i[index show], path: 'arches'
          resources :release_channels,  only: %i[index show], path: 'channels'
          resources :release_engines,   only: %i[index show], path: 'engines'
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
          resources :release_artifacts, only: %i[index show],  path: 'artifacts'
          resource  :release_package,   only: %i[show update], path: 'package'
          resource  :product,           only: %i[show]
          resource  :upgrade,           only: %i[show]

          version_constraint '<=1.0' do
            scope module: :v1x0 do
              resource :release_artifact, only: %i[show destroy], path: 'artifact', as: :v1_0_release_artifact
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

      # NOTE(ezekg) The artifact :show route is defined below, with a less
      #             restrictive mime type constraint.
      resources :release_artifacts, except: %i[show],     path: 'artifacts', constraints: { id: /.*/ }
      resources :release_packages,                        path: 'packages',  constraints: { id: /[^\/]*/ }
      resources :release_engines,   only: %i[index show], path: 'engines',   constraints: { id: /[^\/]*/ }
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

    # Likewise, we have a legacy endpoint that needs to accept a variety of content
    # types without failing due to legacy integrations e.g. old electron-builder
    # versions send binary even though they shouldn't. To resolve this, we'll
    # default to the binary content type, instead of failing with a JSON parse
    # error (because Rails tries to parse the binary as JSON).
    #
    # In reality, this should never have been allowed in the first place. But
    # since it was, electron-builder < v26.6.3 relies on the behavior.
    version_constraint '<=1.0' do
      scope 'releases/:release_id', as: :release, module: 'releases/relationships/v1x0', constraints: { release_id: /[^\/]*/, format: /.*/ } do
        put 'artifact', to: 'release_artifacts#create', defaults: { format: :binary }
      end
    end

    # Artifact and engine actions needs to be a bit loose with the allowed domain and Accept
    # header, so we're defining the route outside of any restrictive domain/subdomain
    # and mime type constraints. Essentially, we want these routes to be able to be
    # accessed regardless of domain or format. The domain aspect mainly is because
    # auth isn't always forwarded during redirects e.g. when redirecting from
    # rubygems.pkg.keygen.sh to api.keygen.sh, which breaks downloads.
    scope defaults: { format: :jsonapi } do
      resources :release_artifacts, only: %i[show], path: 'artifacts', constraints: { id: /.*/, format: /.*/ } do
        member do
          # Vanity URLs where we route by ID but also supply a filename for compatibility
          # with the various package managers that expect a URL with an extension.
          get ':filename', to: 'release_artifacts#show', as: :vanity, constraints: {
            id: UUID_URL_RE,
            filename: /.*/,
          }
        end
      end
    end

    # Release engines can support and respond with a variety of mime types, so
    # we're defining those routes here with their own unique constraints.
    namespace :release_engine, module: :release_engines, path: 'engines' do
      scope :pypi do
        concerns :pypi
      end
      scope :tauri do
        concerns :tauri
      end
      scope :raw do
        concerns :raw
      end
      scope :rubygems do
        concerns :rubygems
      end
      scope :npm do
        concerns :npm
      end
      scope :oci do
        concerns :oci
      end
    end
  end

  if Keygen.multiplayer?
    # Simplified short URLs for artifact distribution
    scope module: :bin, constraints: { domain: Keygen::DOMAIN, subdomain: %w[bin get], format: :jsonapi } do
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

    # Routes for Stdout (e.g. unsubscribe, resubscribe)
    scope module: :stdout, constraints: { domain: Keygen::DOMAIN, subdomain: 'stdout', format: :html } do
      get 'unsub/:ciphertext', constraints: { ciphertext: /.*/ }, to: 'subscribers#unsubscribe', as: :stdout_unsubscribe
      get 'resub/:ciphertext', constraints: { ciphertext: /.*/ }, to: 'subscribers#resubscribe', as: :stdout_resubscribe
    end
  end

  scope module: :api do
    namespace :v1 do
      # Health checks
      scope :health do
        get '/',       to: 'health#general_health'
        get :webhooks, to: 'health#webhook_health'
      end

      constraints domain: Keygen::DOMAIN do
        constraints subdomain: Keygen::SUBDOMAIN do
          if Keygen.multiplayer?
            post :stripe, to: 'stripe#receive_webhook'

            # Pricing
            scope constraints: MimeTypeConstraint.new(:jsonapi, :json, raise_on_no_match: true), defaults: { format: :jsonapi } do
              resources :plans, only: %i[index show]
            end
          end

          # Recover
          scope constraints: MimeTypeConstraint.new(:jsonapi, :json, raise_on_no_match: true), defaults: { format: :jsonapi } do
            post :recover, to: 'recoveries#recover'

            # Account
            case
            when Keygen.multiplayer?
              resources :accounts, param: :account_id, only: %i[show create update destroy]
            when Keygen.singleplayer?
              resources :accounts, param: :account_id, only: %i[show update destroy]
            end
          end
        end

        # Routes with :account_id scope i.e. multiplayer mode. Most of these
        # routes are also available in singleplayer mode for compatibility.
        scope 'accounts/:account_id', as: :account do
          if Keygen.multiplayer?
            constraints subdomain: Keygen::SUBDOMAIN do
              scope constraints: MimeTypeConstraint.new(:jsonapi, :json, raise_on_no_match: true), defaults: { format: :jsonapi } do
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
          end

          concerns :v1
        end
      end

      # Routes without :account_id scope i.e. singleplayer mode. This is
      # also used for CNAME routing (under multiplayer mode).
      concerns :v1
    end
  end

  # Subdomains for our supported distribution engines (i.e. package managers)
  scope constraints: { domain: Keygen::DOMAIN, subdomain: /\.pkg$/ } do
    scope module: 'api/v1/release_engines', constraints: { subdomain: 'pypi.pkg' } do
      case
      when Keygen.multiplayer?
        scope ':account_id', as: :account do
          concerns :pypi
        end
      when Keygen.singleplayer?
        concerns :pypi
      end
    end

    scope module: 'api/v1/release_engines', constraints: { subdomain: 'tauri.pkg' } do
      case
      when Keygen.multiplayer?
        scope ':account_id', as: :account do
          concerns :tauri
        end
      when Keygen.singleplayer?
        concerns :tauri
      end
    end

    scope module: 'api/v1/release_engines', constraints: { subdomain: 'raw.pkg' } do
      case
      when Keygen.multiplayer?
        scope ':account_id', as: :account do
          concerns :raw
        end
      when Keygen.singleplayer?
        concerns :raw
      end
    end

    scope module: 'api/v1/release_engines', constraints: { subdomain: 'rubygems.pkg' } do
      case
      when Keygen.multiplayer?
        scope ':account_id', as: :account do
          concerns :rubygems
        end
      when Keygen.singleplayer?
        concerns :rubygems
      end
    end

    scope module: 'api/v1/release_engines', constraints: { subdomain: 'npm.pkg' } do
      case
      when Keygen.multiplayer?
        scope ':account_id', as: :account do
          concerns :npm
        end
      when Keygen.singleplayer?
        concerns :npm
      end
    end

    scope module: 'api/v1/release_engines', constraints: { subdomain: 'oci.pkg' } do
      # NOTE(ezekg) /v2 namespace is handled here because docker wants it at the root...
      scope :v2 do
        # see: https://github.com/distribution/distribution/blob/main/docs/content/spec/api.md#api-version-check
        # see: https://github.com/opencontainers/distribution-spec/blob/main/spec.md#endpoints
        match '/', via: %i[head get], to: -> env { [200, {'Docker-Distribution-Api-Version': 'registry/2.0'}, []] }

        case
        when Keygen.multiplayer?
          scope ':account_id', as: :account do
            concerns :oci
          end
        when Keygen.singleplayer?
          concerns :oci
        end
      end
    end
  end

  %w[500 503].each do |code|
    match code, to: 'errors#show', code: code.to_i, via: :all
  end

  match '*unmatched_route', to: 'errors#show', code: 404, via: :all
  root to: 'errors#show', code: 404, via: :all
end
