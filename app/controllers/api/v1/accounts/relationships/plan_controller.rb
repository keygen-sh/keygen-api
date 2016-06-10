module Api::V1::Accounts::Relationships
  class PlanController < Api::V1::BaseController
    before_action :authenticate_with_token!
    before_action :set_account, only: [:create]

    # POST /accounts/1/relationships/plan
    def create
      @plan = Plan.find_by_hashid plan_params

      if @account.update(plan: @plan)
        render json: @account
      else
        render json: @account, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
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
