# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class MembersController < Api::V1::BaseController
    has_scope(:type) { |c, s, v| s.for_type(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group

    def index
      members = policy_scope apply_scopes(group.members)
      authorize members

      render jsonapi: members
    end

    def show
      member = group.members.find(params[:id])
      authorize member

      render jsonapi: member
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
