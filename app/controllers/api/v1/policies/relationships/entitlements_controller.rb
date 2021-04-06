# frozen_string_literal: true

module Api::V1::Policies::Relationships
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy

    def index
      authorize @policy, :list_entitlements?

      @entitlements = apply_scopes(@policy.entitlements)

      render jsonapi: @entitlements
    end

    def show
      authorize @policy, :show_entitlement?

      @entitlement = @policy.entitlements.find(params[:id])

      render jsonapi: @entitlement
    end

    def attach
      authorize @policy, :attach_entitlement?

      entitlements_data = entitlement_params.fetch(:data).map do |entitlement|
        entitlement.merge(account_id: current_account.id)
      end

      attached = @policy.policy_entitlements.create!(entitlements_data)

      CreateWebhookEventService.new(
        event: 'policy.entitlements.attached',
        account: current_account,
        resource: attached
      ).execute

      render jsonapi: attached
    end

    def detach
      authorize @policy, :detach_entitlement?

      entitlement_ids = entitlement_params.fetch(:data).map { |e| e[:entitlement_id] }.compact
      policy_entitlements = @policy.policy_entitlements.where(entitlement_id: entitlement_ids)

      # Ensure all entitlements exist. Deleting non-existing policy entitlements would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      if policy_entitlements.size != entitlement_ids.size
        policy_entitlement_ids = policy_entitlements.pluck(:entitlement_id)
        invalid_entitlement_ids = entitlement_ids - policy_entitlement_ids
        invalid_entitlement_id = invalid_entitlement_ids.first
        invalid_idx = entitlement_ids.find_index(invalid_entitlement_id)

        return render_unprocessable_entity(
          detail: "entitlement '#{invalid_entitlement_id}' not found",
          source: {
            pointer: "/data/#{invalid_idx}"
          }
        )
      end

      detached = @policy.policy_entitlements.delete(policy_entitlements)

      CreateWebhookEventService.new(
        event: 'policy.entitlements.detached',
        account: current_account,
        resource: detached
      ).execute
    end

    private

    def set_policy
      @policy = current_account.policies.find params[:policy_id]

      Keygen::Store::Request.store[:current_resource] = @policy
    end

    typed_parameters do
      options strict: true

      on :attach do
        param :data, type: :array do
          items type: :hash do
            param :type, type: :string, inclusion: %w[entitlement entitlements], transform: -> (k, v) { [] }
            param :id, type: :string, transform: -> (k, v) {
              [:entitlement_id, v]
            }
          end
        end
      end

      on :detach do
        param :data, type: :array do
          items type: :hash do
            param :type, type: :string, inclusion: %w[entitlement entitlements], transform: -> (k, v) { [] }
            param :id, type: :string, transform: -> (k, v) {
              [:entitlement_id, v]
            }
          end
        end
      end
    end
  end
end
