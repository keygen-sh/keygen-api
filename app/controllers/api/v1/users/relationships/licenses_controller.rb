# frozen_string_literal: true

module Api::V1::Users::Relationships
  class LicensesController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:policy) { |c, s, v| s.for_policy(v) }
    has_scope :suspended

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    # GET /users/1/licenses
    def index
      @licenses = policy_scope apply_scopes(@user.licenses.preload(:policy))
      authorize @licenses

      render jsonapi: @licenses
    end

    # GET /users/1/licenses/1
    def show
      @license = FindByAliasService.call(scope: @user.licenses, identifier: params[:id], aliases: :key)
      authorize @license

      render jsonapi: @license
    end

    private

    def set_user
      @user = FindByAliasService.call(scope: current_account.users, identifier: params[:user_id], aliases: :email)
      authorize @user, :show?

      Keygen::Store::Request.store[:current_resource] = @user
    end
  end
end
