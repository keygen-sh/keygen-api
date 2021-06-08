# frozen_string_literal: true

module Api::V1
  class MetricsController < Api::V1::BaseController
    has_scope :date, type: :hash, using: [:start, :end], only: :index
    has_scope :page, type: :hash, using: [:number, :size], default: { number: 1, size: 100 }, only: :index

    # TODO(ezekg) Rename metrics => events
    has_scope :metrics, type: :array

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_metric, only: [:show]

    # GET /metrics
    def index
      authorize Metric

      json = Rails.cache.fetch(cache_key, expires_in: 1.minute, race_condition_ttl: 30.seconds) do
        metrics = policy_scope apply_scopes(current_account.metrics.preload(:event_type))
        data = JSONAPI::Serializable::Renderer.new.render(metrics, {
          expose: { url_helpers: Rails.application.routes.url_helpers },
          class: {
            Account: SerializableAccount,
            Metric: SerializableMetric,
            Error: SerializableError
          }
        })

        data.tap do |d|
          d[:links] = pagination_links(metrics)
        end
      end

      render json: json
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
      [:metrics, current_account.id, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end
  end
end
