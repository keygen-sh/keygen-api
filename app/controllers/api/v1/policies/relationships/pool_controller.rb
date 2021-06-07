# frozen_string_literal: true

module Api::V1::Policies::Relationships
  class PoolController < Api::V1::BaseController
    prepend_before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_policy, only: [:index, :show, :pop]

    # GET /policies/1/pool
    def index
      @pool = policy_scope apply_scopes(@policy.pool.preload(:product))
      authorize @pool

      render jsonapi: @pool
    end

    # GET /policies/1/pool/1
    def show
      @pool = @policy.pool.find params[:id]
      authorize @pool

      render jsonapi: @pool
    end

    # DELETE /policies/1/pool
    def pop
      if key = @policy.pop!
        CreateWebhookEventService.new(
          event: "policy.pool.popped",
          account: current_account,
          resource: key
        ).execute

        render jsonapi: key
      else
        render_unprocessable_entity detail: "pool is empty",
          source: { pointer: "/data/relationships/pool" }
      end
    end

    private

    def set_policy
      @policy = current_account.policies.find params[:policy_id]
      authorize @policy, :show?

      if !@policy.pool?
        render_unprocessable_entity detail: "policy does not use a pool",
          source: { pointer: "/data/attributes/usePool" } and return
      end

      Keygen::Store::Request.store[:current_resource] = @policy
    end
  end
end
