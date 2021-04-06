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

      @policy_entitlements = @policy.policy_entitlements

      entitlements = entitlement_params.fetch(:data).map do |entitlement|
        entitlement.merge(account_id: current_account.id)
      end

      @policy_entitlements.transaction do
        attached = @policy_entitlements.create!(entitlements)

        CreateWebhookEventService.new(
          event: 'policy.entitlements.attached',
          account: current_account,
          resource: attached
        ).execute

        render jsonapi: attached
      end
    end

    def detach
      authorize @policy, :detach_entitlement?

      @policy_entitlements = @policy.policy_entitlements

      @policy_entitlements.transaction do
        entitlement_ids = entitlement_params.fetch(:data).collect { |e| e[:entitlement_id] }

        begin
          detached = @policy.entitlements.delete(*entitlement_ids)

          CreateWebhookEventService.new(
            event: 'policy.entitlements.detached',
            account: current_account,
            resource: detached
          ).execute
        rescue ActiveRecord::RecordNotFound
          existing_entitlement_ids = @policy.entitlements.where(id: entitlement_ids).pluck(:id)
          invalid_entitlement_ids = entitlement_ids - existing_entitlement_ids
          invalid_entitlement_id = invalid_entitlement_ids.first
          invalid_idx = entitlement_ids.find_index(invalid_entitlement_id)

          return render_unprocessable_entity(
            detail: "entitlement '#{invalid_entitlement_id}' not found",
            source: {
              pointer: "/data/#{invalid_idx}"
            }
          )
        end
      end
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
