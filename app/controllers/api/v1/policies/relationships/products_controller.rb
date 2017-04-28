module Api::V1::Policies::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy

    # GET /policys/1/product
    def show
      @product = @policy.product
      authorize @product

      render jsonapi: @product
    end

    private

    def set_policy
      @policy = current_account.policies.find params[:policy_id]
      authorize @policy, :show?
    end
  end
end
