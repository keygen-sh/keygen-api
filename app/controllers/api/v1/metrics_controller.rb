module Api::V1
  class MetricsController < Api::V1::BaseController
    has_scope :date, type: :hash, using: [:start, :end], only: :index
    has_scope :page, type: :hash, using: [:number, :size], default: { number: 1, size: 100 }, only: :index
    has_scope :metrics, type: :array

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_metric, only: [:show]

    # GET /metrics
    def index
      @metrics = policy_scope apply_scopes(current_account.metrics).all
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
  end
end
