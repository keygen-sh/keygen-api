# frozen_string_literal: true

module Priv::Analytics
  class ActivitiesController < BaseController
    use_clickhouse

    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    typed_query {
      param :resource, type: :hash, optional: true do
        param :type, type: :string, coerce: true
        param :id, type: :uuid, coerce: true
      end
      param :date, type: :hash, optional: true do
        param :start, type: :date, coerce: true
        param :end, type: :date, coerce: true
      end
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      options = activity_query.reduce({}) do |hash, (key, value)|
        hash.merge(
          case { key => value }
          in resource: { type: resource_type, id: resource_id }
            { resource_type:, resource_id: }
          in date: { start: start_date, end: end_date }
            { start_date:, end_date: }
          else
            { key => value }
          end
        )
      end

      activity = Analytics::Activity.new(
        params[:activity_id],
        **options,
      )

      unless activity.valid?
        render_bad_request *activity.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
          sources: {
            parameters: {
              resource_type: 'resource[type]',
              resource_id: 'resource[id]',
              start_date: 'date[start]',
              end_date: 'date[end]',
            },
          },
        )

        return
      end

      data = Rails.cache.fetch activity.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        activity.as_json
      end

      render json: { data: }
    end
  end
end
