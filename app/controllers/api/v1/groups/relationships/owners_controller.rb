# frozen_string_literal: true

module Api::V1::Groups::Relationships
  class OwnersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :scope_to_current_environment!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group

    authorize :group

    def index
      owners = apply_pagination(authorized_scope(apply_scopes(group.owners)))
      authorize! owners,
        with: Groups::GroupOwnerPolicy

      render jsonapi: owners
    end

    def show
      owner = group.owners.find(params[:id])
      authorize! owner,
        with: Groups::GroupOwnerPolicy

      render jsonapi: owner
    end

    typed_params {
      format :jsonapi

      param :data, type: :array do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[user users] }
          param :id, type: :string, as: :user_id
        end
      end
    }
    def attach
      authorize! with: Groups::GroupOwnerPolicy

      owners_data = owner_params.map do |owner|
        owner.merge(account_id: current_account.id)
      end

      attached = group.owners.create!(owners_data)

      BroadcastEventService.call(
        event: 'group.owners.attached',
        account: current_account,
        resource: attached,
      )

      render jsonapi: attached
    end

    typed_params {
      format :jsonapi

      param :data, type: :array do
        items type: :hash do
          param :type, type: :string, inclusion: { in: %w[user users] }
          param :id, type: :string, as: :user_id
        end
      end
    }
    def detach
      authorize! with: Groups::GroupOwnerPolicy

      user_ids = owner_params.collect { |e| e[:user_id] }.compact
      owners   = group.owners.where(user_id: user_ids)

      # Ensure all owners exist. Deleting non-existing owners would be a noop, but
      # responding with a 2xx status code is a confusing DX.
      if owners.size != user_ids.size
        valid_user_ids   = owners.pluck(:user_id)
        invalid_user_ids = user_ids - valid_user_ids
        invalid_user_id  = invalid_user_ids.first
        invalid_idx      = user_ids.find_index(invalid_user_id)

        return render_unprocessable_entity(
          detail: "owner relationship for user '#{invalid_user_id}' not found",
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
      scoped_groups = authorized_scope(current_account.groups)

      @group = scoped_groups.find(params[:group_id])

      Current.resource = group
    end
  end
end
