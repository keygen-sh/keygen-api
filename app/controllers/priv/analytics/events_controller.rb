# frozen_string_literal: true

module Priv::Analytics
  class EventsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    before_action :require_clickhouse!

    typed_query {
      param :start_date, type: :date, coerce: true, optional: true
      param :end_date, type: :date, coerce: true, optional: true
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      data = cached do
        Analytics::Event.call(params[:event_id], account: current_account, environment: current_environment, **event_query)
                        .as_json
      end

      render json: { data: }
    rescue Analytics::EventNotFoundError
      render_not_found
    end

    private

    def cached(&) = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL, &)
    def cache_key
      [:analytics, :events, params[:event_id], current_account.id, current_environment&.id, params[:start_date], params[:end_date], CACHE_KEY_VERSION].compact.join(':')
    end
  end
end
