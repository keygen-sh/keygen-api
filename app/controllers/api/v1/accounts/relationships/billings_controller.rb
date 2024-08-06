# frozen_string_literal: true

module Api::V1::Accounts::Relationships
  class BillingsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate!
    before_action :set_billing

    def show
      authorize! billing,
        with: Accounts::BillingPolicy

      render jsonapi: billing
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[billing billings] }
        param :attributes, type: :hash do
          param :token, type: :string, optional: true
          param :coupon, type: :string, optional: true
        end
      end
    }
    def update
      authorize! billing,
        with: Accounts::BillingPolicy

      status = Billings::UpdateCustomerService.call(
        customer: billing.customer_id,
        token: billing_params[:token],
        coupon: billing_params[:coupon],
      )

      if status
        BroadcastEventService.call(
          event: 'account.billing.updated',
          account: current_account,
          resource: billing,
        )

        head :accepted
      else
        render_unprocessable_entity
      end
    end

    private

    attr_reader :billing

    def set_billing
      @billing = current_account.billing!
    end
  end
end
