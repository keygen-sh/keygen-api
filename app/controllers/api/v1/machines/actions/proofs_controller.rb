# frozen_string_literal: true

module Api::V1::Machines::Actions
  class ProofsController < Api::V1::BaseController
    prepend_before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    # POST /machines/1/generate-offline-proof
    def generate_offline_proof
      authorize @machine

      dataset = proof_params.dig(:meta, :dataset)
      proof = @machine.generate_proof(dataset: dataset)
      meta = { proof: proof }

      CreateWebhookEventService.new(
        event: "machine.proofs.generated",
        account: current_account,
        resource: @machine,
        meta: meta
      ).execute

      render jsonapi: @machine, meta: meta
    end

    private

    def set_machine
      @machine = FindByAliasService.new(current_account.machines, params[:id], aliases: :fingerprint).call

      Keygen::Store::Request.store[:current_resource] = @machine
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
