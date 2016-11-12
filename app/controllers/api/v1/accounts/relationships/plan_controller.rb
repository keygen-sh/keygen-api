module Api::V1::Accounts::Relationships
  class PlanController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account

    # POST /accounts/1/relationships/plan
    def update
      render_not_found and return unless @account

      authorize @account

      @plan = Plan.find_by_hashid plan_parameters

      render_unprocessable_entity detail: "must be a valid plan", source: {
        pointer: "/data/relationships/plan" } and return if @plan.nil?

      status = Billings::UpdateSubscriptionService.new(
        subscription: @account.billing.subscription_id,
        plan: @plan.plan_id
      ).execute

      if status
        if @account.update(plan: @plan)
          render json: @account
        else
          render_unprocessable_resource @account
        end
      else
        render_unprocessable_entity detail: "must have a valid subscription", source: {
          pointer: "/data/relationships/billing" }
      end
    end

    private

    attr_reader :parameters

    def set_account
      @account = Account.find_by_hashid params[:account_id]
    end

    def plan_parameters
      parameters[:plan]
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :update do
          param :plan, type: :string
        end
      end
    end
  end
end
