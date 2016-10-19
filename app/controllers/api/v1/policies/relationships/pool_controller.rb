module Api::V1::Policies::Relationships
  class PoolController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_policy, only: [:pop]

    # DELETE /policies/1/relationships/pool
    def pop
      render_not_found and return unless @policy

      authorize @policy

      unless @policy.use_pool
        render_unprocessable_entity detail: "policy does not use a pool",
          source: { pointer: "/data/attributes/usePool" } and return
      end

      if key = @policy.pop!
        render json: key
      else
        render_unprocessable_entity detail: "pool is empty",
          source: { pointer: "/data/relationships/pool" }
      end
    end

    private

    def set_policy
      @policy = @current_account.policies.find_by_hashid params[:policy_id]
    end
  end
end
