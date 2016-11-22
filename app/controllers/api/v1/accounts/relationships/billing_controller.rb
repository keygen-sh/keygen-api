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

    # PATCH /accounts/1/relationships/billing
    def update
      render_not_found and return unless @billing

      authorize @billing

      status = Billings::UpdateCustomerService.new(
        customer: @billing.customer_id,
        token: parameters[:token]
      ).execute

      if status
        head :accepted
      else
        render_unprocessable_entity
      end
    end

    private

    attr_reader :parameters

    def set_billing
      @billing = Account.find_by_hashid(params[:account_id])&.billing
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :update do
          param :token, type: :string
        end
      end
    end
  end
end
