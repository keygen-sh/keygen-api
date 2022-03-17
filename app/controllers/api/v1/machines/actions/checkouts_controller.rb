# frozen_string_literal: true

module Api::V1::Machines::Actions
  class CheckoutsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    def checkout
      authorize machine

      kwargs = checkout_query.to_h.symbolize_keys.slice(:include, :encrypt, :ttl)
      file   = MachineCheckoutService.call(
        account: current_account,
        machine: machine,
        **kwargs,
      )

      BroadcastEventService.call(
        event: 'machine.checkout',
        account: current_account,
        resource: machine,
      )

      response.headers['Content-Disposition'] = %(attachment; filename="machine+#{machine.id}.lic")
      response.headers['Content-Type']        = 'application/octet-stream'

      render body: file
    end

    private

    attr_reader :machine

    def set_machine
      scoped_machines = policy_scope(current_account.machines)

      @machine = FindByAliasService.call(scope: scoped_machines, identifier: params[:id], aliases: :fingerprint)

      Current.resource = machine
    end

    typed_query do
      on :checkout do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          param :include, type: :array, coerce: true, optional: true
          param :encrypt, type: :boolean, coerce: true, optional: true
          param :ttl, type: :integer, coerce: true, optional: true
        end
      end
    end
  end
end
