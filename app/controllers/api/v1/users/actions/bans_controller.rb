# frozen_string_literal: true

module Api::V1::Users::Actions
  class BansController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate!
    before_action :set_user

    def ban
      authorize! user

      user.ban!

      BroadcastEventService.call(
        event: 'user.banned',
        account: current_account,
        resource: user,
      )

      render jsonapi: user
    end

    def unban
      authorize! user

      user.unban!

      BroadcastEventService.call(
        event: 'user.unbanned',
        account: current_account,
        resource: user,
      )

      render jsonapi: user
    end

    private

    attr_reader :user

    def set_user
      scoped_users = authorized_scope(current_account.users)

      @user = FindByAliasService.call(scoped_users, id: params[:id], aliases: :email)

      Current.resource = user
    end
  end
end
