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

    authorize :user

    def index
      licenses = apply_pagination(authorized_scope(apply_scopes(user.licenses)).preload(:role, :owner, :policy, :product))
      authorize! licenses,
        with: Users::LicensePolicy

      render jsonapi: licenses
    end

    def show
      license = FindByAliasService.call(user.licenses, id: params[:id], aliases: :key)
      authorize! license,
        with: Users::LicensePolicy

      render jsonapi: license
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
