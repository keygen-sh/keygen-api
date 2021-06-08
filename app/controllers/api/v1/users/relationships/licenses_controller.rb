# frozen_string_literal: true

module Api::V1::Users::Relationships
  class LicensesController < Api::V1::BaseController
    has_scope :suspended
    has_scope :product
    has_scope :policy

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
      @license = FindByAliasService.new(@user.licenses, params[:id], aliases: :key).call
      authorize @license

      render jsonapi: @license
    end

    private

    def set_user
      @user = FindByAliasService.new(current_account.users, params[:user_id], aliases: :email).call
      authorize @user, :show?

      Keygen::Store::Request.store[:current_resource] = @user
    end
  end
end
