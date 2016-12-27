module Api::V1::Accounts::Relationships
  class BillingController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_billing

    # GET /accounts/1/billing
    def show
      render_not_found and return unless @billing

      authorize @billing

      render jsonapi: @billing
    end

    # PATCH /accounts/1/billing
    def update
      render_not_found and return unless @billing

      authorize @billing

      status = Billings::UpdateCustomerService.new(
        customer: @billing.customer_id,
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
      @billing = Account.find(params[:account_id])&.billing
    end

    typed_parameters transform: true do
      options strict: true

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[billing billings]
          param :attributes, type: :hash do
            param :token, type: :string
          end
        end
      end
    end
  end
end
