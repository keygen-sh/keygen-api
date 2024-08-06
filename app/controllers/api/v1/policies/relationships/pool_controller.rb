# frozen_string_literal: true

module Api::V1::Policies::Relationships
  class PoolController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_policy, only: %i[index show pop]

    authorize :policy

    def index
      keys = apply_pagination(authorized_scope(apply_scopes(policy.pool)).preload(:product))
      authorize! keys,
        with: Policies::PoolPolicy

      render jsonapi: keys
    end

    def show
      key = policy.pool.find(params[:id])
      authorize! key,
        with: Policies::PoolPolicy

      render jsonapi: key
    end

    def pop
      authorize! with: Policies::PoolPolicy
      key = policy.pop!

      BroadcastEventService.call(
        event: 'policy.pool.popped',
        account: current_account,
        resource: key,
      )

      render jsonapi: key
    rescue Policy::UnsupportedPoolError
      render_unprocessable_entity(
        source: { pointer: '/data/relationships/pool' },
        detail: 'pool is not supported',
      )
    rescue Policy::EmptyPoolError
      render_unprocessable_entity(
        source: { pointer: '/data/relationships/pool' },
        detail: 'pool is empty',
      )
    end

    private

    attr_reader :policy

    def set_policy
      scoped_policies = authorized_scope(current_account.policies)

      @policy = scoped_policies.find(params[:policy_id])

      Current.resource = policy
    end
  end
end
