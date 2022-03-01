# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class OwnersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group

    def index
      owners = policy_scope apply_scopes(group.owners)
      authorize owners

      render jsonapi: owners
    end

    def show
      owner = group.owners.find(params[:id])
      authorize owner

      render jsonapi: owner
    end

    def attach
      authorize group

      owners_data = owner_params.fetch(:data).map do |owner|
        owner.merge(
          account_id: current_account.id,
          owner_type: User.name,
        )
      end

      attached = group.owners.create!(owners_data)

      BroadcastEventService.call(
        event: 'group.owners.attached',
        account: current_account,
        resource: attached,
      )

      render jsonapi: attached
    end

    def detach
      authorize group

      owner_ids = owner_params.fetch(:data).map { |e| e[:owner_id] }.compact
      owners    = group.owners.where(
        owner_type: User.name,
        owner_id: owner_ids,
      )

      # Ensure all owners exist. Deleting non-existing owners would be a noop, but
      # responding with a 2xx status code is a confusing DX.
      if owners.size != owner_ids.size
        valid_owner_ids   = owners.pluck(:owner_id)
        invalid_owner_ids = owner_ids - valid_owner_ids
        invalid_owner_id  = invalid_owner_ids.first
        invalid_idx       = owner_ids.find_index(invalid_owner_id)

        return render_unprocessable_entity(
          detail: "owner '#{invalid_owner_id}' relationship not found",
          source: {
            pointer: "/data/#{invalid_idx}"
          }
        )
      end

      detached = group.owners.delete(owners)

      BroadcastEventService.call(
        event: 'group.owners.detached',
        account: current_account,
        resource: detached,
      )
    end

    private

    attr_reader :group

    def set_group
      @group = current_account.groups.find(params[:group_id])
      authorize group, :show?

      Current.resource = group
    end

    typed_parameters do
      options strict: true

      on :attach do
        param :data, type: :array do
          items type: :hash do
            param :type, type: :string, inclusion: %w[user users], transform: -> (k, v) { [] }
            param :id, type: :string, transform: -> (k, v) {
              [:owner_id, v]
            }
          end
        end
      end

      on :detach do
        param :data, type: :array do
          items type: :hash do
            param :type, type: :string, inclusion: %w[user users], transform: -> (k, v) { [] }
            param :id, type: :string, transform: -> (k, v) {
              [:owner_id, v]
            }
          end
        end
      end
    end
  end
end
