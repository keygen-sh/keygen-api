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
        render_unprocessable_entity(
          detail: "cannot change to a policy for another product",
          source: {
            pointer: "/data/relationships/policy"
          }
        )
        return
      when new_policy.present? && old_policy.encrypted? != new_policy.encrypted?
        render_unprocessable_entity(
          detail: "cannot change from an encrypted policy to an unencrypted policy (or vice-versa)",
          source: {
            pointer: "/data/relationships/policy"
          }
        )
        return
      when new_policy.present? && old_policy.pool? != new_policy.pool?
        render_unprocessable_entity(
          detail: "cannot change from a pooled policy to an unpooled policy (or vice-versa)",
          source: {
            pointer: "/data/relationships/policy"
          }
        )
        return
      when current_bearer.role?(:user) && new_policy&.protected?
        render_forbidden
        return
      end

      if @license.update(policy: new_policy)
        CreateWebhookEventService.new(
          event: "license.policy.updated",
          account: current_account,
          resource: @license
        ).execute

        render jsonapi: @license
      else
        render_unprocessable_resource @license
      end
    end

    private

    def set_license
      # FIXME(ezekg) This allows the license to be looked up by ID or
      #              key, but this is pretty messy.
      id = params[:license_id] if params[:license_id] =~ UUID_REGEX # Only include when it's a UUID (else pg throws an err)
      key = params[:license_id]

      @license = current_account.licenses.where("id = ? OR key = ?", id, key).first
      raise ActiveRecord::RecordNotFound if @license.nil?

      authorize @license, :show?
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
