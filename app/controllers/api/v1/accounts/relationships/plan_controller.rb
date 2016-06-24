module Api::V1::Accounts::Relationships
  class PlanController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account, only: [:update]

    # PATCH/PUT /accounts/1/relationships/plan
    def update
      authorize @account

      @plan = Plan.find_by_hashid plan_params

      if @account.update(plan: @plan)
        render json: @account
      else
        render_unprocessable_resource @account
      end
    end

    private

    def set_account
      @account = Account.find_by_hashid params[:account_id]
      @account || render_not_found
    end

    def plan_params
      params.require :plan
    end
  end
end
