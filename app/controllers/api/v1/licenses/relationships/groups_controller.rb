# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class GroupsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    def show
      group = license.group!
      authorize! group,
        with: Licenses::GroupPolicy

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
        with: Licenses::GroupPolicy

      # reuse id so that model validations are run for invalid groups
      license.update!(group_id:)

      BroadcastEventService.call(
        event: 'license.group.updated',
        account: current_account,
        resource: license,
      )

      # FIXME(ezekg) this should be the group linkage
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
