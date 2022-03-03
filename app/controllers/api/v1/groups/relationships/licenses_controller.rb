# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class LicensesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group

    def index
      licenses = policy_scope(apply_scopes(group.licenses)).preload(:user, :policy)
      authorize licenses

      render jsonapi: licenses
    end

    def show
      license = FindByAliasService.call(scope: group.licenses, identifier: params[:id], aliases: :key)
      authorize license

      render jsonapi: license
    end

    private

    attr_reader :group

    def set_group
      @group = current_account.groups.find(params[:group_id])
      authorize group, :show?

      Current.resource = group
    end
  end
end
