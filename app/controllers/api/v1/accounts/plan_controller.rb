module Api::V1::Accounts
  class PlanController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account

    # PUT /accounts/1/plan
    def update
      authorize @account

      @plan = Plan.find plan_params[:id]

      status = Billings::UpdateSubscriptionService.new(
        subscription: @account.billing.subscription_id,
        plan: @plan.plan_id
      ).execute

      if status
        if @account.update(plan: @plan)
          render jsonapi: @account
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity detail: "must have a valid subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    private

    def set_account
      @account = Account.find params[:id]
    end

    typed_parameters transform: true do
      options strict: true

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[plan plans]
          param :id, type: :string
        end
      end
    end
  end
end
