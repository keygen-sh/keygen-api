# frozen_string_literal: true

module Api::V1::Policies::Relationships
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy

    authorize :policy

    def index
      entitlements = apply_pagination(authorized_scope(apply_scopes(policy.entitlements)))
      authorize! entitlements,
        with: Policies::EntitlementPolicy

      render jsonapi: entitlements
    end

    def show
      entitlement = policy.entitlements.find(params[:id])
      authorize! entitlement,
        with: Policies::EntitlementPolicy

      render jsonapi: entitlement
    end

    typed_params {
      format :jsonapi

      param :data, type: :array, length: { minimum: 1 } do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[entitlement entitlements] }
          param :id, type: :uuid, as: :entitlement_id
        end
      end
    }
    def attach
      entitlements = current_account.entitlements.where(id: entitlement_ids)
      authorize! entitlements,
        with: Policies::EntitlementPolicy

      attached = policy.policy_entitlements.create!(
        entitlement_ids.map {{ account_id: current_account.id, entitlement_id: _1 }},
      )

      BroadcastEventService.call(
        event: 'policy.entitlements.attached',
        account: current_account,
        resource: attached,
      )

      render jsonapi: attached
    end

    typed_params {
      format :jsonapi

      param :data, type: :array, length: { minimum: 1 } do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[entitlement entitlements] }
          param :id, type: :uuid, as: :entitlement_id
        end
      end
    }
    def detach
      entitlements = current_account.entitlements.where(id: entitlement_ids)
      authorize! entitlements,
        with: Policies::EntitlementPolicy

      # Ensure all entitlements exist. Again, non-existing license entitlements would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      policy_entitlements = policy.policy_entitlements.where(entitlement_id: entitlement_ids)

      unless policy_entitlements.size == entitlement_ids.size
        policy_entitlement_ids  = policy_entitlements.pluck(:entitlement_id)
        invalid_entitlement_ids = entitlement_ids - policy_entitlement_ids
        invalid_entitlement_id  = invalid_entitlement_ids.first
        invalid_idx             = entitlement_ids.find_index(invalid_entitlement_id)

        return render_unprocessable_entity(
          detail: "entitlement '#{invalid_entitlement_id}' relationship not found",
          source: {
            pointer: "/data/#{invalid_idx}",
          },
        )
      end

      detached = policy.policy_entitlements.delete(policy_entitlements)

      BroadcastEventService.call(
        event: 'policy.entitlements.detached',
        account: current_account,
        resource: detached,
      )
    end

    private

    attr_reader :policy

    def entitlement_ids = entitlement_params.pluck(:entitlement_id)

    def set_policy
      scoped_policies = authorized_scope(current_account.policies)

      @policy = scoped_policies.find(params[:policy_id])

      Current.resource = policy
    end
  end
end
