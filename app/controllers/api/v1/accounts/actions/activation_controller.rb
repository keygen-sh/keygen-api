module Api::V1::Accounts::Actions
  class ActivationController < Api::V1::BaseController
    before_action :set_account, only: [:activate]

    # POST /accounts/1/actions/activate
    def activate
      skip_authorization

      if @account.activation_token == params[:activation_token]
        if @account.activated?
          render_conflict detail: "has already been used", source: {
            pointer: "/data/attributes/activationToken" }
        elsif !@account.active? && !@account.trialing?
          render_unauthorized detail: "is not active", source: {
            pointer: "/data/attributes/status" }
        elsif @account.update(activated: true)
          render json: @account
        else
          render_unprocessable_resource @account
        end
      else
        render_unauthorized detail: "is not valid", source: {
          pointer: "/data/attributes/activationToken" }
      end
    end

    private

    def set_account
      @account = Account.find_by_hashid params[:account_id]
      @account || render_not_found
    end
  end
end
