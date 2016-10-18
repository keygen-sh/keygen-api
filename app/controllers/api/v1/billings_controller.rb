module Api::V1
  class BillingsController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_billing, only: [:show, :update]

    # GET /billings/1
    def show
      render_not_found and return unless @billing

      authorize @billing

      render json: @billing
    end

    # PATCH/PUT /billings/1
    def update
      render_not_found and return unless @billing

      authorize @billing

      status = ::Billings::UpdateCustomerService.new(
        id: @billing.external_customer_id,
        token: billing_params[:token]
      ).execute

      if status
        head :accepted
      else
        render_unprocessable_entity
      end
    end

    private

    def set_billing
      @billing = @current_account.billing
    end

    def billing_params
      params.require(:billing).permit :token
    end
  end
end
