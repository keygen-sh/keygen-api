# frozen_string_literal: true

module Api::V1::Machines::Relationships
  class GroupsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    authorize :machine

    def show
      group = machine.group!
      authorize! group,
        with: Machines::GroupPolicy

      render jsonapi: group
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, allow_nil: true do
        param :type, type: :string, inclusion: { in: %w[group groups] }
        param :id, type: :uuid
      end
    }
    def update
      group_id = group_params[:id]
      group    = current_account.groups.find_by(id: group_id) unless group_id.nil?
      authorize! group,
        with: Machines::GroupPolicy

      # reuse id so that model validations are run for invalid groups
      machine.update!(group_id:)

      BroadcastEventService.call(
        event: 'machine.group.updated',
        account: current_account,
        resource: machine,
      )

      # FIXME(ezekg) this should be the group linkage
      render jsonapi: machine
    end

    private

    attr_reader :machine

    def set_machine
      scoped_machines = authorized_scope(current_account.machines)

      @machine = FindByAliasService.call(scoped_machines, id: params[:machine_id], aliases: :fingerprint)

      Current.resource = machine
    end
  end
end
