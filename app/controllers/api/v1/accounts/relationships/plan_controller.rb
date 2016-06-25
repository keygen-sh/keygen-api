module Api::V1::Accounts::Relationships
  class PlanController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account, only: [:create]

    # POST /accounts/1/relationships/plan
    def create
      authorize @account

      @plan = Plan.find_by_hashid plan_params
      subscription = update_plan_with_external_service

      if @plan && subscription
        if @account.update(plan: @plan)
          render json: @account
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity detail: "must exist", source: {
          pointer: "/data/attributes/plan" }
      end
    end

    private

    def update_plan_with_external_service
      SubscriptionService.new({
        id: @account.billing.external_subscription_id,
        plan: @plan.external_plan_id
      }).update
    end

    def set_account
      @account = Account.find_by_hashid params[:account_id]
      @account || render_not_found
    end

    def plan_params
      params.require :plan
    end
  end
end
