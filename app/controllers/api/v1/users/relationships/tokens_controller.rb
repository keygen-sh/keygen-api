# frozen_string_literal: true

module Api::V1::Users::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    # GET /users/1/tokens
    def index
      @tokens = policy_scope apply_scopes(@user.tokens)
      authorize @tokens

      render jsonapi: @tokens
    end

    # GET /users/1/tokens/1
    def show
      @token = @user.tokens.find params[:id]
      authorize @token

      render jsonapi: @token
    end

    private

    def set_user
      @user = current_account.users.find params[:user_id]
      authorize @user, :read_tokens?

      Keygen::Store::Request.store[:current_resource] = @user
    end
  end
end
