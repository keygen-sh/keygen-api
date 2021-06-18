# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ConstraintsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def index
      authorize release, :list_constraints?

      constraints = apply_scopes(release.constraints)

      render jsonapi: constraints
    end

    def show
      authorize release, :show_constraint?

      constraint = release.constraints.find(params[:id])

      render jsonapi: constraint
    end

    def attach
      authorize release, :attach_constraints?

      constraints_data = constraint_params
        .uniq { |constraint| constraint[:entitlement_id] }
        .map { |constraint|
          constraint.merge(account_id: current_account.id)
        }

      attached = release.constraints.create!(constraints_data)

      BroadcastEventService.call(
        event: 'release.constraints.attached',
        account: current_account,
        resource: attached
      )

      render jsonapi: attached
    end

    def detach
      authorize release, :detach_constraints?

      entitlement_ids = constraint_params
        .map { |e| e[:entitlement_id] }
        .compact
        .uniq

      release_constraints = release.constraints.where(entitlement_id: entitlement_ids)

      # Ensure all entitlement constraints exist. Deleting non-existent constraints would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      if release_constraints.size != entitlement_ids.size
        release_entitlement_ids = release_constraints.pluck(:entitlement_id)
        invalid_entitlement_ids = entitlement_ids - release_entitlement_ids
        invalid_entitlement_id  = invalid_entitlement_ids.first
        invalid_entitlement_idx = entitlement_ids.find_index(invalid_entitlement_id)

        return render_unprocessable_entity(
          detail: "constraint entitlement '#{invalid_entitlement_id}' relationship not found",
          source: {
            pointer: "/data/#{invalid_entitlement_idx}/relationships/entitlement"
          }
        )
      end

      detached = release.constraints.delete(release_constraints)

      BroadcastEventService.call(
        event: 'release.constraints.detached',
        account: current_account,
        resource: detached
      )
    end

    private

    attr_reader :release

    def set_release
      @release = current_account.releases.find params[:release_id]
      authorize release, :show?

      Keygen::Store::Request.store[:current_resource] = release
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :attach do
        param :data, type: :array do
          items type: :hash do
            param :type, type: :string, inclusion: %w[constraint constraints], transform: -> (k, v) { [] }
            param :relationships, type: :hash do
              param :entitlement, type: :hash do
                param :data, type: :hash do
                  param :type, type: :string, inclusion: %w[entitlement entitlements]
                  param :id, type: :string
                end
              end
            end
          end
        end
      end

      on :detach do
        param :data, type: :array do
          items type: :hash do
            param :type, type: :string, inclusion: %w[constraint constraints], transform: -> (k, v) { [] }
            param :relationships, type: :hash do
              param :entitlement, type: :hash do
                param :data, type: :hash do
                  param :type, type: :string, inclusion: %w[entitlement entitlements]
                  param :id, type: :string
                end
              end
            end
          end
        end
      end
    end
  end
end
