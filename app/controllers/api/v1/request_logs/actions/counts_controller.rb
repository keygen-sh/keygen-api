module Api::V1::RequestLogs::Actions
  class CountsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    # GET /request-logs/actions/count
    def count
      authorize RequestLog

      json = Rails.cache.fetch(cache_key, expires_in: 15.minutes) do
        logs = policy_scope(apply_scopes(current_account.request_logs))
                    .current_period
                    .unscope(:order)
                    .group_by_day(:created_at)
                    .count

        {
          meta: logs
        }
      end

      render json: json
    end

    private

    def cache_key
      [:logs, current_account.id, :count, request.query_string.parameterize].select(&:present?).join ":"
    end
  end
end