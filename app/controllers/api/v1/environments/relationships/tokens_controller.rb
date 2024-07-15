# frozen_string_literal: true

module Api::V1::Environments::Relationships
  class TokensController < Api::V1::BaseController
    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_environment

    def index
      tokens = apply_pagination(authorized_scope(apply_scopes(environment.tokens.owned)).preload(:account, bearer: %i[role]))
      authorize! tokens,
        with: Environments::TokenPolicy

      render jsonapi: tokens
    end

    def show
      token = environment.tokens.owned.find(params[:id])
      authorize! token,
        with: Environments::TokenPolicy

      render jsonapi: token
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, optional: true do
        param :type, type: :string, inclusion: { in: %w[token tokens] }
        param :attributes, type: :hash do
          param :expiry, type: :time, allow_nil: true, optional: true, coerce: true
          param :name, type: :string, allow_nil: true, optional: true

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_account.ent? && current_bearer&.has_role?(:admin, :environment) } do
              items type: :string
            end
          end
        end
        param :relationships, type: :hash, optional: true do
          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :uuid
              end
            end
          end
        end
      end
    }
    def create
      kwargs = token_params.slice(
        :environment_id,
        :permissions,
        :expiry,
        :name,
      )

      token = current_account.tokens.new(bearer: environment, environment:, **kwargs)
      authorize! token,
        with: Environments::TokenPolicy

      if token.save
        BroadcastEventService.call(
          event: 'token.generated',
          account: current_account,
          resource: token,
        )

        render jsonapi: token, status: :created, location: v1_account_token_url(token.account, token)
      else
        render_unprocessable_resource token
      end
    end

    private

    attr_reader :environment

    def set_environment
      scoped_environments = authorized_scope(current_account.environments)

      @environment = scoped_environments.find(params[:environment_id])

      Current.resource = environment
    end

    def require_ee!
      super(entitlements: %i[environments])
    end
  end
end
