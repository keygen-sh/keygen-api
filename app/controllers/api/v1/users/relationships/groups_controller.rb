# frozen_string_literal: true

module Api::V1::Users::Relationships
  class GroupsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    def show
      group = user.group
      authorize group

      render jsonapi: group
    end

    def update
      authorize user, :change_group?

      user.update!(group_id: group_params[:id])

      BroadcastEventService.call(
        event: 'user.group.updated',
        account: current_account,
        resource: user,
      )

      render jsonapi: user
    end

    private

    attr_reader :user

    def set_user
      @user = FindByAliasService.call(scope: current_account.users, identifier: params[:user_id], aliases: :email)
      authorize user, :show?

      Current.resource = user
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :update do
        param :data, type: :hash, allow_nil: true do
          param :type, type: :string, inclusion: %w[group groups]
          param :id, type: :string
        end
      end
    end
  end
end
