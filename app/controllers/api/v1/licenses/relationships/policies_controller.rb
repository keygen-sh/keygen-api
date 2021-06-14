# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/policy
    def show
      @policy = @license.policy
      authorize @policy

      render jsonapi: @policy
    end

    # PUT /licenses/1/policy
    def update
      authorize @license, :upgrade?

      new_policy = current_account.policies.find_by id: policy_params[:id]
      old_policy = @license.policy

      case
      when new_policy.present? && old_policy.product != new_policy.product
        return render_unprocessable_entity(
          detail: "cannot change to a policy for another product",
          source: {
            pointer: "/data/relationships/policy"
          }
        )
      when new_policy.present? && old_policy.encrypted? != new_policy.encrypted?
        return render_unprocessable_entity(
          detail: "cannot change from an encrypted policy to an unencrypted policy (or vice-versa)",
          source: {
            pointer: "/data/relationships/policy"
          }
        )
      when new_policy.present? && old_policy.pool? != new_policy.pool?
        return render_unprocessable_entity(
          detail: "cannot change from a pooled policy to an unpooled policy (or vice-versa)",
          source: {
            pointer: "/data/relationships/policy"
          }
        )
      when new_policy.present? && old_policy.scheme != new_policy.scheme
        return render_unprocessable_entity(
          detail: "cannot change to a policy with a different scheme",
          source: {
            pointer: "/data/relationships/policy"
          }
        )
      when new_policy.present? && old_policy.fingerprint_uniqueness_strategy != new_policy.fingerprint_uniqueness_strategy
        return render_unprocessable_entity(
          detail: "cannot change to a policy with a different fingerprint uniqueness strategy",
          source: {
            pointer: "/data/relationships/policy"
          }
        )
      when current_bearer.has_role?(:user) && new_policy&.protected?
        return render_forbidden
      end

      if @license.update(policy: new_policy)
        CreateWebhookEventService.call(
          event: "license.policy.updated",
          account: current_account,
          resource: @license
        )

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    private

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:license_id], aliases: :key)
      authorize @license, :show?

      Keygen::Store::Request.store[:current_resource] = @license
    end

    typed_parameters transform: true do
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
