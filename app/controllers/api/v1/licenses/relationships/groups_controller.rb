# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class GroupsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def show
      group = license.group
      authorize! license, group

      render jsonapi: group
    end

    def update
      authorize! license, Group

      license.update!(group_id: group_params[:id])

      BroadcastEventService.call(
        event: 'license.group.updated',
        account: current_account,
        resource: license,
      )

      render jsonapi: license
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = policy_scope(current_account.licenses)

      @license = FindByAliasService.call(scope: scoped_licenses, identifier: params[:license_id], aliases: :key)

      Current.resource = license
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
