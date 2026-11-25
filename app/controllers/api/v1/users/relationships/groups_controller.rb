# frozen_string_literal: true

module Api::V1::Users::Relationships
  class GroupsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    authorize :user

    def show
      group = user.group
      authorize! group,
        with: Users::GroupPolicy

      render jsonapi: group
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, allow_nil: true do
        param :type, type: :string, inclusion: { in: %w[group groups] }
        param :id, type: :uuid
      end
    }
    def update
      group_id = group_params[:id]
      group    = current_account.groups.find_by(id: group_id) unless group_id.nil?
      authorize! group,
        with: Users::GroupPolicy

      # reuse id so that model validations are run for invalid groups
      user.update!(group_id:)

      BroadcastEventService.call(
        event: 'user.group.updated',
        account: current_account,
        resource: user,
      )

      # FIXME(ezekg) this should be the group linkage
      render jsonapi: user
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
