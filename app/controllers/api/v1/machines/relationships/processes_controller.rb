# frozen_string_literal: true

module Api::V1::Machines::Relationships
  class ProcessesController < Api::V1::BaseController
    has_scope(:status) { |c, s, v| s.with_status(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    def index
      processes = apply_pagination(policy_scope(apply_scopes(machine.processes)).preload(:machine, :license, :policy, :product, :group))
      authorize processes

      render jsonapi: processes
    end

    def show
      process = machine.processes.find(params[:id])
      authorize process

      render jsonapi: process
    end

    private

    attr_reader :machine

    def set_machine
      scoped_machines = policy_scope(current_account.machines)

      @machine = FindByAliasService.call(scope: scoped_machines, identifier: params[:machine_id], aliases: :fingerprint)
      authorize machine, :show?

      Current.resource = machine
    end
  end
end
