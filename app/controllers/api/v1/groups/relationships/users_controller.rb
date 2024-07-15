# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_group

    authorize :group

    def index
      users = apply_pagination(authorized_scope(apply_scopes(group.users), with: Groups::UserPolicy).preload(:role, :any_active_licenses))
      authorize! users,
        with: Groups::UserPolicy

      render jsonapi: users
    end

    def show
      user = FindByAliasService.call(group.users, id: params[:id], aliases: :email)
      authorize! user,
        with: Groups::UserPolicy

      render jsonapi: user
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
