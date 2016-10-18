module Api::V1::Accounts::Relationships
  class PlanController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account

    # POST /accounts/1/relationships/plan
    def update
      render_not_found and return unless @account

      authorize @account

      @plan = Plan.find_by_hashid plan_params

      if @plan
        subscription = ::Billings::UpdateSubscriptionService.new(
          id: @account.billing.external_subscription_id,
          plan: @plan.external_plan_id
        ).execute
      end

      if subscription
        if @account.update(plan: @plan)
          render json: @account
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity detail: "must exist", source: {
          pointer: "/data/attributes/billing" }
      end
    end

    private

    def set_account
      @account = Account.find_by_hashid params[:account_id]
    end

    def plan_params
      params.require :plan
    end
  end
end
