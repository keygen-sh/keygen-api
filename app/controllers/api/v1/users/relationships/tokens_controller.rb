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

            param :permissions, type: :array, optional: true, if: -> { current_account.ent? && current_bearer&.has_role?(:admin, :product) } do
              items type: :string
            end
          end
        end
      end
    }
    def create
      authorize! with: Users::TokenPolicy

      kwargs = token_params.slice(
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

      @user = FindByAliasService.call(scoped_users, id: params[:user_id], aliases: :email)

      Current.resource = user
    end
  end
end
