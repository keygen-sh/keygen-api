# frozen_string_literal: true

module Priv::Analytics
  class RequestsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    before_action :require_clickhouse!

    typed_query {
      param :start_date, type: :date, coerce: true, optional: true
      param :end_date, type: :date, coerce: true, optional: true
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      request_analytics = Analytics::Request.new(**request_query)

      unless request_analytics.valid?
        render_bad_request detail: request_analytics.errors.full_messages.to_sentence,
                           source: { parameter: request_analytics.errors.attribute_names.first }
        return
      end

      data = cached { request_analytics.as_json }

      render json: { data: }
    end

    private

    def cached(&) = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL, &)
    def cache_key
      [:analytics, :requests, current_account.id, current_environment&.id, params[:start_date], params[:end_date], CACHE_KEY_VERSION].compact.join(':')
    end
  end
end
