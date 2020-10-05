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

      dataset = proof_params.dig(:meta, :proof)
      proof = @machine.generate_proof(dataset: dataset)

      render jsonapi: @machine, meta: { proof: proof }
    end

    private

    def set_machine
      @machine = current_account.machines.find params[:id]
    end

    typed_parameters do
      options strict: true

      on :generate_offline_proof do
        param :meta, type: :hash, optional: true do
          param :proof, type: :hash
        end
      end
    end
  end
end
