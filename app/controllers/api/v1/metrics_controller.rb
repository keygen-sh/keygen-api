module Api::V1
  class MetricsController < Api::V1::BaseController
    has_scope :metrics, type: :array

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_metric, only: [:show]

    # GET /metrics
    def index
      @metrics = Rails.cache.fetch cache_key, expires_in: 15.minutes do
        policy_scope(apply_scopes(current_account.metrics)).all
      end
      authorize @metrics

      render jsonapi: @metrics
    end

    # GET /metrics/1
    def show
      authorize @metric

      render jsonapi: @metric
    end

    private

    def set_metric
      @metric = current_account.metrics.find params[:id]
    end

    def cache_key(id = nil)
      [current_account.id, "metrics", id, request.query_string.parameterize].reject { |s| s.nil? || s.empty? }.join "/"
    end
  end
end
