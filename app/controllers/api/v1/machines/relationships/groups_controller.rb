# frozen_string_literal: true

module Api::V1::Machines::Relationships
  class GroupsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    def show
      group = machine.group
      authorize group

      render jsonapi: group
    end

    def update
      authorize machine, :change_group?

      machine.update!(group_id: group_params[:id])

      BroadcastEventService.call(
        event: 'machine.group.updated',
        account: current_account,
        resource: machine,
      )

      render jsonapi: machine
    end

    private

    attr_reader :machine

    def set_machine
      @machine = FindByAliasService.call(scope: current_account.machines, identifier: params[:machine_id], aliases: :fingerprint)
      authorize machine, :show?

      Current.resource = machine
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :update do
        param :data, type: :hash, allow_nil: true do
          param :type, type: :string, inclusion: %w[group groups]
          param :id, type: :string
        end
      end
    end
  end
end
