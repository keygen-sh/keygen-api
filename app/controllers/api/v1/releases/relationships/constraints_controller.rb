# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ConstraintsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def index
      authorize release, :list_constraints?

      entitlements = apply_scopes(release.entitlements)

      render jsonapi: entitlements
    end

    def show
      authorize release, :show_constraint?

      entitlement = release.entitlements.find(params[:id])

      render jsonapi: entitlement
    end

    def attach
      authorize release, :attach_constraint?

      entitlements_data = constraint_params.fetch(:data).map do |entitlement|
        entitlement.merge(account_id: current_account.id)
      end

      attached = release.entitlement_constraints.create!(entitlements_data)

      BroadcastEventService.new(
        event: 'release.constraints.attached',
        account: current_account,
        resource: attached
      ).execute

      render jsonapi: attached
    end

    def detach
      authorize release, :detach_constraint?

      entitlement_ids = constraint_params.fetch(:data).map { |e| e[:entitlement_id] }.compact
      release_entitlements = release.entitlement_constraints.where(entitlement_id: entitlement_ids)

      # Ensure all entitlements exist. Deleting non-existing release entitlements would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      if release_entitlements.size != entitlement_ids.size
        release_entitlement_ids = release_entitlements.pluck(:entitlement_id)
        invalid_entitlement_ids = entitlement_ids - release_entitlement_ids
        invalid_entitlement_id = invalid_entitlement_ids.first
        invalid_idx = entitlement_ids.find_index(invalid_entitlement_id)

        return render_unprocessable_entity(
          detail: "constraint '#{invalid_entitlement_id}' relationship not found",
          source: {
            pointer: "/data/#{invalid_idx}"
          }
        )
      end

      detached = release.entitlement_constraints.delete(release_entitlements)

      BroadcastEventService.new(
        event: 'release.constraints.detached',
        account: current_account,
        resource: detached
      ).execute
    end

    private

    attr_reader :release

    def set_release
      @release = current_account.releases.find params[:release_id]
      authorize release, :show?

      Keygen::Store::Request.store[:current_resource] = release
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
