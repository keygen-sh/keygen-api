module Api::V1::Accounts::Relationships
  class BillingController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_billing

    # GET /accounts/1/relationships/billing
    def show
      render_not_found and return unless @billing

      authorize @billing

      render json: @billing
    end

    # PATCH/PUT /accounts/1/relationships/billing
    def update
      render_not_found and return unless @billing

      authorize @billing

      status = ::Billings::UpdateCustomerService.new(
        id: @billing.customer_id,
        token: token_params
      ).execute

      if status
        head :accepted
      else
        render_unprocessable_entity
      end
    end

    private

    def set_billing
      @billing = Account.find_by_hashid(params[:account_id])&.billing
    end

    def token_params
      params.require :token
    end
  end
end
