# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_license

    authorize :license

    def show
      policy = license.policy
      authorize! policy,
        with: Licenses::PolicyPolicy

      render jsonapi: policy
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[policy policies] }
        param :id, type: :uuid
      end
    }
    def update
      policy = current_account.policies.find_by(id: policy_params[:id])
      authorize! policy,
        with: Licenses::PolicyPolicy

      license.transfer!(policy)

      BroadcastEventService.call(
        event: 'license.policy.updated',
        account: current_account,
        resource: license,
      )

      # FIXME(ezekg) This should be the policy
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
