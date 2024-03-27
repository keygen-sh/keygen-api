# frozen_string_literal: true

module Api::V1::Machines::Relationships
  class OwnersController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    authorize :machine

    def show
      owner = machine.owner
      authorize! owner,
        with: Machines::OwnerPolicy

      render jsonapi: owner
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, allow_nil: true do
        param :type, type: :string, inclusion: { in: %w[user users] }
        param :id, type: :uuid
      end
    }
    def update
      owner = machine.owner
      authorize! owner,
        with: Machines::OwnerPolicy

      machine.update!(owner_id: owner_params[:id])

      BroadcastEventService.call(
        event: 'machine.owner.updated',
        account: current_account,
        resource: machine,
      )

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
