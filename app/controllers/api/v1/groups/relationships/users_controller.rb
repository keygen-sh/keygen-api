# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group

    def index
      users = policy_scope(apply_scopes(group.users)).preload(:role)
      authorize users

      render jsonapi: users
    end

    def show
      user = FindByAliasService.call(scope: group.users, identifier: params[:id], aliases: :email)
      authorize user

      render jsonapi: user
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
