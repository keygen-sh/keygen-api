module Api::V1::Accounts::Actions
  class ActivationController < Api::V1::BaseController
    before_action :set_account, only: [:activate]

    # POST /accounts/1/actions/activate
    def activate
      render_not_found and return unless @account

      skip_authorization

      if @account.activation_token == activation_params
        if @account.activated?
          render_conflict detail: "has already been used", source: {
            pointer: "/data/attributes/activationToken" }
        elsif !@account.pending? && !@account.active? && !@account.trialing?
          render_forbidden detail: "is #{@account.status}", source: {
            pointer: "/data/attributes/status" }
        elsif @account.update(activated: true)
          render json: @account
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity detail: "is not valid", source: {
          pointer: "/data/attributes/activationToken" }
      end
    end

    private

    def set_account
      @account = Account.find_by_hashid params[:account_id]
    end

    def activation_params
      params.require :activation_token
    end
  end
end
