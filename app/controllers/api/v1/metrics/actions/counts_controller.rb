# frozen_string_literal: true

module Api::V1::Metrics::Actions
  class CountsController < Api::V1::BaseController
    has_scope :metrics, type: :array

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    # GET /metrics/actions/count
    def count
      authorize Metric

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        metrics = policy_scope(apply_scopes(current_account.metrics))
                    .current_period
                    .unscope(:order)
                    .group_by_day(:created_at, last: 14)
                    .count

        {
          meta: metrics
        }
      end

      render json: json
    end

    private

    def cache_key
      [:metrics, current_account.id, :count, Digest::SHA2.hexdigest(request.query_string)].join ":"
    end
  end
end