# frozen_string_literal: true

module Priv::Analytics
  class ActivitiesController < BaseController
    CACHE_TTL      = 10.minutes
    CACHE_RACE_TTL = 1.minute

    before_action :require_clickhouse!

    typed_query {
      param :start_date, type: :date, coerce: true, optional: true
      param :end_date, type: :date, coerce: true, optional: true
      param :resource_type, type: :string, coerce: true, optional: true
      param :resource_id, type: :uuid, coerce: true, optional: true
    }
    def show
      authorize! with: Accounts::AnalyticsPolicy

      activity = Analytics::Activity.new(params[:activity_id], **activity_query)

      unless activity.valid?
        render_bad_request detail: activity.errors.full_messages.to_sentence,
                           source: { parameter: activity.errors.attribute_names.first }
        return
      end

      data = cached { activity.as_json }

      render json: { data: }
    end

    private

    def cached(&) = Rails.cache.fetch(cache_key, expires_in: CACHE_TTL, race_condition_ttl: CACHE_RACE_TTL, &)
    def cache_key
      [:analytics, :activities, params[:activity_id], current_account.id, current_environment&.id, params[:start_date], params[:end_date], params[:resource_type], params[:resource_id], CACHE_KEY_VERSION].compact.join(':')
    end
  end
end
