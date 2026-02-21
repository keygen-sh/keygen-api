# frozen_string_literal: true

module Priv::Analytics
  class EventsController < BaseController
    use_clickhouse

    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    typed_query {
      param :resource, type: :hash, optional: true, collapse: { format: :parent_child } do
        param :type, type: :string, coerce: true
        param :id, type: :uuid, coerce: true
      end
      param :date, type: :hash, optional: true, collapse: { format: :child_parent } do
        param :start, type: :date, coerce: true
        param :end, type: :date, coerce: true
      end
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      series = Analytics::Series.new(
        :events,
        event_pattern: params[:event],
        **event_query,
      )

      unless series.valid?
        render_bad_request *series.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
          sources: {
            parameters: {
              resource_type: 'resource[type]',
              resource_id: 'resource[id]',
              start_date: 'date[start]',
              end_date: 'date[end]',
              metrics: 'event',
            },
          },
        )

        return
      end

      data = Rails.cache.fetch series.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        series.as_json
      end

      render json: { data: }
    end
  end
end
