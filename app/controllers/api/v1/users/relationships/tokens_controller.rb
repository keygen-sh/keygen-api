# frozen_string_literal: true

module Api::V1::Users::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    def index
      authorize user, :list_tokens?

      tokens = apply_pagination(policy_scope(apply_scopes(user.tokens)))
      authorize tokens

      render jsonapi: tokens
    end

    def show
      authorize user, :show_token?

      token = user.tokens.find params[:id]
      authorize token

      render jsonapi: token
    end

    def create
      authorize user, :generate_token?

      kwargs = token_params.to_h.symbolize_keys.slice(
        :permissions,
        :expiry,
        :name,
      )

      token = TokenGeneratorService.call(
        account: current_account,
        bearer: user,
        # NOTE(ezekg) This is a default (may be overridden by kwargs)
        expiry: user.user? ? Time.current + Token::TOKEN_DURATION : nil,
        **kwargs,
      )

      return render_unprocessable_resource(token) unless
        token.valid?

      BroadcastEventService.call(
        event: 'token.generated',
        account: current_account,
        resource: token,
      )

      render jsonapi: token
    end

    private

    attr_reader :user

    def set_user
      @user = FindByAliasService.call(scope: current_account.users, identifier: params[:user_id], aliases: :email)
      authorize user, :show?

      Current.resource = user
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash, optional: true do
          param :type, type: :string, inclusion: %w[token tokens]
          param :attributes, type: :hash do
            param :expiry, type: :datetime, allow_nil: true, optional: true, coerce: true
            param :name, type: :string, allow_nil: true, optional: true
            if current_bearer&.has_role?(:admin, :product)
              param :permissions, type: :array, optional: true do
                items type: :string
              end
            end
          end
        end
      end
    end
  end
end
