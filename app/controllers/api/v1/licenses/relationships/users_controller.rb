# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    def show
      user = license.user
      authorize! user,
        with: Licenses::UserPolicy

      render jsonapi: user
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, allow_nil: true do
        param :type, type: :string, inclusion: { in: %w[user users] }
        param :id, type: :uuid
      end
    }
    def update
      user = license.user
      authorize! user,
        with: Licenses::UserPolicy

      license.update!(user_id: user_params[:id])

      BroadcastEventService.call(
        event: 'license.user.updated',
        account: current_account,
        resource: license,
      )

      # FIXME(ezekg) This should be the user
      render jsonapi: license
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:license_id], aliases: :key)

      Current.resource = license
    end
  end
end
