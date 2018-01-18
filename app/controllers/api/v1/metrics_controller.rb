module Api::V1
  class MetricsController < Api::V1::BaseController
    has_scope :date, type: :hash, using: [:start, :end], only: :index
    has_scope :metrics, type: :array

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_metric, only: [:show]

    # GET /metrics
    def index
      @metrics = Rails.cache.fetch cache_key, expires_in: 5.minutes do
        metrics = policy_scope apply_scopes(current_account.metrics).all
        JSONAPI::Serializable::Renderer.new.render(metrics[0...100], {
          expose: { url_helpers: Rails.application.routes.url_helpers },
          class: {
            Account: SerializableAccount,
            Metric: SerializableMetric,
            Error: SerializableError
          }
        })
      end
      authorize Metric

      render json: @metrics
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

    def cache_key
      [:metrics, current_account.id, current_bearer.id, request.query_string.parameterize].select(&:present?).join "/"
    end
  end
end
