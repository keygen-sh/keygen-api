# frozen_string_literal: true

module Api::V1
  class MetricsController < Api::V1::BaseController
    has_scope :date, type: :hash, using: [:start, :end], only: :index
    has_scope(:metrics, type: :array) { |c, s, v| s.with_events(v) }
    has_scope(:events, type: :array) { |c, s, v| s.with_events(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_metric, only: %i[show]

    def index
      authorize! with: MetricPolicy

      json = Rails.cache.fetch(cache_key, expires_in: 1.minute, race_condition_ttl: 30.seconds) do
        metrics = apply_pagination(authorized_scope(apply_scopes(current_account.metrics)).preload(:event_type))
        data    = Keygen::JSONAPI.render(metrics)

        data.tap { it[:links] = pagination_links(metrics) }
      end

      render json: json
    end

    def show
      authorize! metric,
        with: MetricPolicy

      render jsonapi: metric
    end

    private

    attr_reader :metric

    def set_metric
      scoped_metrics = authorized_scope(current_account.metrics)

      @metric = scoped_metrics.find(params[:id])

      Current.resource = metric
    end

    def cache_key
      [:metrics, current_account.id, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end
  end
end
