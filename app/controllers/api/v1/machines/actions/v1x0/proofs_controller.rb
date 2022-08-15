# frozen_string_literal: true

module Api::V1::Machines::Actions::V1x0
  class ProofsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    authorize :machine

    def create
      authorize! with: Machines::V1x0::ProofPolicy

      dataset = proof_params.dig(:meta, :dataset)
      proof   = machine.generate_proof(dataset:)
      meta    = { proof: }

      BroadcastEventService.call(
        event: 'machine.proofs.generated',
        account: current_account,
        resource: machine,
        meta:,
      )

      render jsonapi: machine, meta:
    end

    private

    attr_reader :machine

    def set_machine
      scoped_machines = authorized_scope(current_account.machines)

      @machine = FindByAliasService.call(scope: scoped_machines, identifier: params[:id], aliases: :fingerprint)

      Current.resource = machine
    end

    typed_parameters do
      options strict: true

      on :create do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          param :meta, type: :hash, optional: true do
            param :dataset, type: :hash
          end
        end
      end
    end
  end
end
