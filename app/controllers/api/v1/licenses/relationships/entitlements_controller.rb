# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def index
      authorize @license, :list_entitlements?

      @entitlements = apply_scopes(@license.entitlements)

      render jsonapi: @entitlements
    end

    def show
      authorize @license, :show_entitlement?

      @entitlement = @license.entitlements.find(params[:id])

      render jsonapi: @entitlement
    end

    def attach
      authorize @license, :attach_entitlement?

      entitlements_data = entitlement_params.fetch(:data).map do |entitlement|
        entitlement.merge(account_id: current_account.id)
      end

      attached = @license.license_entitlements.create!(entitlements_data)

      CreateWebhookEventService.new(
        event: 'license.entitlements.attached',
        account: current_account,
        resource: attached
      ).execute

      render jsonapi: attached
    end

    def detach
      authorize @license, :detach_entitlement?

      entitlement_ids = entitlement_params.fetch(:data).map { |e| e[:entitlement_id] }.compact

      # Block policy entitlements from being detached. These entitlements need to be detached
      # via the policy. This request wouldn't detach the entitlements, but since non-existing
      # license entitlement IDs are currently noops, responding with a 2xx status code is
      # confusing for the end-user, so we're going to error out early for a better DX.
      if @license.policy_entitlements.exists?(entitlement_id: entitlement_ids)
        policy_entitlements_ids = @license.policy_entitlements.where(entitlement_id: entitlement_ids).pluck(:entitlement_id)
        forbidden_entitlement_ids = entitlement_ids & policy_entitlements_ids
        forbidden_entitlement_id = forbidden_entitlement_ids.first
        forbidden_idx = entitlement_ids.find_index(forbidden_entitlement_id)

        return render_forbidden(
          detail: "cannot detach entitlement '#{forbidden_entitlement_id}' (entitlement is attached through policy)",
          source: {
            pointer: "/data/#{forbidden_idx}"
          }
        )
      end

      # Ensure all entitlements exist. Again, non-existing license entitlements would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      license_entitlements = @license.license_entitlements.where(entitlement_id: entitlement_ids)

      if license_entitlements.size != entitlement_ids.size
        license_entitlement_ids = license_entitlements.pluck(:entitlement_id)
        invalid_entitlement_ids = entitlement_ids - license_entitlement_ids
        invalid_entitlement_id = invalid_entitlement_ids.first
        invalid_idx = entitlement_ids.find_index(invalid_entitlement_id)

        return render_unprocessable_entity(
          detail: "entitlement '#{invalid_entitlement_id}' not found",
          source: {
            pointer: "/data/#{invalid_idx}"
          }
        )
      end

      detached = @license.license_entitlements.delete(license_entitlements)

      CreateWebhookEventService.new(
        event: 'license.entitlements.detached',
        account: current_account,
        resource: detached
      ).execute
    end

    private

    def set_license
      @license = FindByAliasService.new(current_account.licenses, params[:license_id], aliases: :key).call

      Keygen::Store::Request.store[:current_resource] = @license
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
