# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def show
      policy = license.policy
      authorize! license, policy

      render jsonapi: policy
    end

    def update
      authorize! license, license.policy

      policy = current_account.policies.find_by(id: policy_params[:id])
      authorize! license, policy if
        policy.present?

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
      scoped_licenses = policy_scope(current_account.licenses)

      @license = FindByAliasService.call(scope: scoped_licenses, identifier: params[:license_id], aliases: :key)

      Current.resource = license
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[policy policies]
          param :id, type: :string
        end
      end
    end
  end
end
