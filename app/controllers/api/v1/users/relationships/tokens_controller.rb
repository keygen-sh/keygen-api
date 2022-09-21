# frozen_string_literal: true

module Api::V1::Users::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    authorize :user

    def index
      tokens = apply_pagination(authorized_scope(apply_scopes(user.tokens)))
      authorize! tokens,
        with: Users::TokenPolicy

      render jsonapi: tokens
    end

    def show
      token = user.tokens.find params[:id]
      authorize! token,
        with: Users::TokenPolicy

      render jsonapi: token
    end

    def create
      authorize! with: Users::TokenPolicy

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
      scoped_users = authorized_scope(current_account.users)

      @user = FindByAliasService.call(scope: scoped_users, identifier: params[:user_id], aliases: :email)

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
            if current_account.ent? && current_bearer&.has_role?(:admin, :product)
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
