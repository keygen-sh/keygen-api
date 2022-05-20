# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ConstraintsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def index
      authorize release, :list_constraints?

      constraints = apply_pagination(apply_scopes(release.constraints))

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

      constraint_ids = constraint_params.collect { |e| e[:id] }.compact
      constraints = release.constraints.where(id: constraint_ids)

      # Ensure all entitlement constraints exist. Deleting non-existent constraints would be
      # a noop, but responding with a 2xx status code is a confusing DX.
      if constraints.size != constraint_ids.size
        existing_constraint_ids = constraints.pluck(:id)
        invalid_constraint_ids = constraint_ids - existing_constraint_ids
        invalid_constraint_id = invalid_constraint_ids.first
        invalid_idx = constraint_ids.find_index(invalid_constraint_id)

        return render_unprocessable_entity(
          detail: "constraint '#{invalid_constraint_id}' relationship not found",
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

    def set_release
      scoped_releases = policy_scope(current_account.releases)

      @release = FindByAliasService.call(scope: scoped_releases, identifier: params[:release_id], aliases: %i[version tag])
      authorize release, :show?

      Current.resource = release
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
            param :id, type: :string
          end
        end
      end
    end
  end
end
