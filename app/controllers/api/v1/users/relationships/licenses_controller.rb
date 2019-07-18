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
      @license = @user.licenses.find params[:id]
      authorize @license

      render jsonapi: @license
    end

    private

    def set_user
      @user = current_account.users.find params[:user_id]
      authorize @user, :show?
    end
  end
end
