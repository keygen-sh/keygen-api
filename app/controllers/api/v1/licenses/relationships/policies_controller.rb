# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/policy
    def show
      policy = license.policy
      authorize policy

      render jsonapi: policy
    end

    # PUT /licenses/1/policy
    def update
      authorize license, :change_policy?

      new_policy = current_account.policies.find_by(id: policy_params[:id])
      old_policy = license.policy

      license.transaction do
        license.transfer!(new_policy)

        # Need to perform the authz again to assert new policy can be accessed
        authorize license, :change_policy?
      end

      BroadcastEventService.call(
        event: "license.policy.updated",
        account: current_account,
        resource: license
      )

      render jsonapi: license
    end

    private

    attr_reader :license

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:license_id], aliases: :key)
      authorize license, :show?

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
