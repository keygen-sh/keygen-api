# frozen_string_literal: true

module Api::V1
  class GroupsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_group, only: [:show, :update, :destroy]

    def index
      groups = apply_pagination(policy_scope(apply_scopes(current_account.groups)))
      authorize groups

      render jsonapi: groups
    end

    def show
      authorize group

      render jsonapi: group
    end

    def create
      group = current_account.groups.new(group_params)
      authorize group

      if group.save
        BroadcastEventService.call(
          event: 'group.created',
          account: current_account,
          resource: group,
        )

        render jsonapi: group, status: :created, location: v1_account_group_url(group.account, group)
      else
        render_unprocessable_resource group
      end
    end

    def update
      authorize group

      if group.update(group_params)
        BroadcastEventService.call(
          event: 'group.updated',
          account: current_account,
          resource: group,
        )

        render jsonapi: group
      else
        render_unprocessable_resource group
      end
    end

    def destroy
      authorize group

      BroadcastEventService.call(
        event: 'group.deleted',
        account: current_account,
        resource: group,
      )

      group.destroy_async
    end

    private

    attr_reader :group

    def set_group
      @group = current_account.groups.find(params[:id])

      Current.resource = group
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[group groups]
          param :attributes, type: :hash do
            param :name, type: :string
            param :max_users, type: :integer, optional: true
            param :max_licenses, type: :integer, optional: true
            param :max_machines, type: :integer, optional: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[group groups]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :max_users, type: :integer, optional: true, allow_nil: true
            param :max_licenses, type: :integer, optional: true, allow_nil: true
            param :max_machines, type: :integer, optional: true, allow_nil: true
            param :metadata, type: :hash, allow_non_scalars: true, optional: true
          end
        end
      end
    end
  end
end
