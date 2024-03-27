# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ReleaseEntitlementConstraintsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    authorize :release

    def index
      constraints = apply_pagination(authorized_scope(apply_scopes(release.constraints)))
      authorize! constraints,
        with: Releases::ReleaseEntitlementConstraintPolicy

      render jsonapi: constraints
    end

    def show
      constraint = release.constraints.find(params[:id])
      authorize! constraint,
        with: Releases::ReleaseEntitlementConstraintPolicy

      render jsonapi: constraint
    end

    typed_params {
      format :jsonapi

      param :data, type: :array do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[constraint constraints] }
          param :relationships, type: :hash do
            param :entitlement, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: { in: %w[entitlement entitlements] }
                param :id, type: :uuid
              end
            end
          end
        end
      end
    }
    def attach
      entitlements = current_account.entitlements.where(id: entitlement_ids)
      authorize! entitlements,
        with: Releases::ReleaseEntitlementConstraintPolicy

      attached = release.constraints.create!(
        entitlement_ids.map {{ account_id: current_account.id, entitlement_id: _1 }},
      )

      BroadcastEventService.call(
        event: 'release.constraints.attached',
        account: current_account,
        resource: attached
      )

      render jsonapi: attached
    end

    typed_params {
      format :jsonapi

      param :data, type: :array do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[constraint constraints] }
          param :id, type: :uuid
        end
      end
    }
    def detach
      constraints = release.constraints.where(id: constraint_ids)
      authorize! constraints,
        with: Releases::ReleaseEntitlementConstraintPolicy

      constraints = release.constraints.where(id: constraint_ids)

      # Ensure all entitlement constraints exist. Deleting non-existent constraints would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      unless constraints.size == constraint_ids.size
        existing_constraint_ids = constraints.pluck(:id)
        invalid_constraint_ids  = constraint_ids - existing_constraint_ids
        invalid_constraint_id   = invalid_constraint_ids.first
        invalid_idx             = constraint_ids.find_index(invalid_constraint_id)

        return render_unprocessable_entity(
          detail: "cannot detach constraint '#{invalid_constraint_id}' (constraint is not attached)",
          source: {
            pointer: "/data/#{invalid_idx}"
          }
        )
      end

      detached = release.constraints.delete(constraints)

      BroadcastEventService.call(
        event: 'release.constraints.detached',
        account: current_account,
        resource: detached
      )
    end

    private

    attr_reader :release

    def entitlement_ids = release_entitlement_constraint_params.pluck(:entitlement_id)
    def constraint_ids  = release_entitlement_constraint_params.pluck(:id)

    def set_release
      scoped_releases = authorized_scope(current_account.releases)

      @release = FindByAliasService.call(scoped_releases, id: params[:release_id], aliases: %i[version tag])

      Current.resource = release
    end
  end
end
