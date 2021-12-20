# frozen_string_literal: true

module Api::V1::Machines::Actions
  class ProofsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    # POST /machines/1/generate-offline-proof
    def generate_offline_proof
      authorize @machine

      dataset = proof_params.dig(:meta, :dataset)
      proof = @machine.generate_proof(dataset: dataset)
      meta = { proof: proof }

      BroadcastEventService.call(
        event: "machine.proofs.generated",
        account: current_account,
        resource: @machine,
        meta: meta
      )

      render jsonapi: @machine, meta: meta
    end

    private

    def set_machine
      scoped_machines = policy_scope(current_account.machines)

      @machine = FindByAliasService.call(scope: scoped_machines, identifier: params[:id], aliases: :fingerprint)

      Current.resource = @machine
    end

    typed_parameters do
      options strict: true

      on :generate_offline_proof do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          param :meta, type: :hash, optional: true do
            param :dataset, type: :hash
          end
        end
      end
    end
  end
end
