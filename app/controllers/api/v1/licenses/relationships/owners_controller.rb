# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class OwnersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    def show
      owner = license.owner
      authorize! owner,
        with: Licenses::OwnerPolicy

      render jsonapi: owner
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, allow_nil: true do
        param :type, type: :string, inclusion: { in: %w[user users] }
        param :id, type: :uuid
      end
    }
    def update
      owner = license.owner
      authorize! owner,
        with: Licenses::OwnerPolicy

      license.update!(user_id: owner_params[:id])

      BroadcastEventService.call(
        event: 'license.owner.updated',
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
