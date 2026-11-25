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
      owner_id = owner_params[:id]
      owner    = current_account.users.find_by(id: owner_id) unless owner_id.nil?
      authorize! owner,
        with: Licenses::OwnerPolicy

      # reuse id so that model validations are run for invalid owners
      license.update!(owner_id:)

      BroadcastEventService.call(
        event: 'license.owner.updated',
        account: current_account,
        resource: license,
      )

      # FIXME(ezekg) this should be the user linkage
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
