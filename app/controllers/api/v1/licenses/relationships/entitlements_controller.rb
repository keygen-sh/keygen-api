# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    def index
      entitlements = apply_pagination(authorized_scope(apply_scopes(license.entitlements)))
      authorize! entitlements,
        with: Licenses::EntitlementPolicy

      render jsonapi: entitlements
    end

    def show
      entitlement = license.entitlements.find(params[:id])
      authorize! entitlement,
        with: Licenses::EntitlementPolicy

      render jsonapi: entitlement
    end


    typed_params {
      format :jsonapi

      param :data, type: :array, length: { minimum: 1, maximum: 100 } do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[entitlement entitlements] }
          param :id, type: :uuid, as: :entitlement_id
        end
      end
    }
    def attach
      entitlements = current_account.entitlements.where(id: entitlement_ids)
      authorize! entitlements,
        with: Licenses::EntitlementPolicy

      attached = license.transaction do
        license.license_entitlements.create!(
          entitlement_ids.map {{ account_id: current_account.id, entitlement_id: it }},
        )
      end

      BroadcastEventService.call(
        event: 'license.entitlements.attached',
        account: current_account,
        resource: attached,
      )

      render jsonapi: attached
    end

    typed_params {
      format :jsonapi

      param :data, type: :array, length: { minimum: 1, maximum: 100 } do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[entitlement entitlements] }
          param :id, type: :uuid, as: :entitlement_id
        end
      end
    }
    def detach
      entitlements = current_account.entitlements.where(id: entitlement_ids)
      authorize! entitlements,
        with: Licenses::EntitlementPolicy

      # Block policy entitlements from being detached. These entitlements need to be detached
      # via the policy. This request wouldn't detach the entitlements, but since non-existing
      # license entitlement IDs are currently noops, responding with a 2xx status code is
      # confusing for the end-user, so we're going to error out early for a better DX.
      policy_entitlements = license.policy_entitlements.where(entitlement_id: entitlement_ids)

      if policy_entitlements.exists?
        policy_entitlements_ids   = policy_entitlements.pluck(:entitlement_id)
        forbidden_entitlement_ids = entitlement_ids & policy_entitlements_ids
        forbidden_entitlement_id  = forbidden_entitlement_ids.first
        forbidden_idx             = entitlement_ids.find_index(forbidden_entitlement_id)

        return render_forbidden(
          detail: "cannot detach entitlement '#{forbidden_entitlement_id}' (entitlement is attached through policy)",
          source: {
            pointer: "/data/#{forbidden_idx}",
          },
        )
      end

      # Ensure all entitlements exist. Again, non-existing license entitlements would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      license_entitlements = license.license_entitlements.where(entitlement_id: entitlement_ids)

      unless license_entitlements.size == entitlement_ids.size
        license_entitlement_ids = license_entitlements.pluck(:entitlement_id)
        invalid_entitlement_ids = entitlement_ids - license_entitlement_ids
        invalid_entitlement_id  = invalid_entitlement_ids.first
        invalid_idx             = entitlement_ids.find_index(invalid_entitlement_id)

        return render_unprocessable_entity(
          detail: "cannot detach entitlement '#{invalid_entitlement_id}' (entitlement is not attached)",
          source: {
            pointer: "/data/#{invalid_idx}",
          },
        )
      end

      detached = license.transaction do
        license.license_entitlements.destroy(license_entitlements)
      end

      BroadcastEventService.call(
        event: 'license.entitlements.detached',
        account: current_account,
        resource: detached,
      )
    end

    private

    attr_reader :license

    def entitlement_ids = entitlement_params.pluck(:entitlement_id)

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:license_id], aliases: :key)

      Current.resource = license
    end
  end
end
