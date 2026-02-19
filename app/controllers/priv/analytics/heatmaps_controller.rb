# frozen_string_literal: true

module Priv::Analytics
  class HeatmapsController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    typed_query {
      param :date, type: :hash, optional: true, collapse: { format: :child_parent } do
        param :start, type: :date, coerce: true
        param :end, type: :date, coerce: true
      end
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      heatmap = Analytics::Heatmap.new(
        params[:heatmap_id],
        **heatmap_query,
      )

      unless heatmap.valid?
        render_bad_request *heatmap.errors.as_jsonapi(
          title: 'Bad request',
          source: :parameter,
          sources: {
            parameters: {
              start_date: 'date[start]',
              end_date: 'date[end]',
            },
          },
        )

        return
      end

      data = Rails.cache.fetch heatmap.cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL do
        heatmap.as_json
      end

      render json: { data: }
    rescue Analytics::HeatmapNotFoundError
      render_not_found
    end
  end
end
