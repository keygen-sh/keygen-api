# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class LicensesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group

    authorize :group

    def index
      licenses = apply_pagination(authorized_scope(apply_scopes(group.licenses), with: Groups::LicensePolicy).preload(:role, :user, :policy, :product))
      authorize! licenses,
        with: Groups::LicensePolicy

      render jsonapi: licenses
    end

    def show
      license = FindByAliasService.call(group.licenses, id: params[:id], aliases: :key)
      authorize! license,
        with: Groups::LicensePolicy

      render jsonapi: license
    end

    private

    attr_reader :group

    def set_group
      scoped_groups = authorized_scope(current_account.groups)

      @group = scoped_groups.find(params[:group_id])

      Current.resource = group
    end
  end
end
