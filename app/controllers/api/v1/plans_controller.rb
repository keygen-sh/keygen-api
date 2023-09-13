# frozen_string_literal: true

module Api::V1
  class PlansController < Api::V1::BaseController
    before_action :set_plan, only: %i[show]

    def index
      authorize! with: PlanPolicy

      json = Rails.cache.fetch(cache_key, expires_in: 1.hour, race_condition_ttl: 1.minute) do
        plans = apply_pagination(apply_scopes(Plan.visible).reorder('price ASC NULLS FIRST'))
        data = Keygen::JSONAPI.render(plans)

        data
      end

      render json: json
    end

    def show
      authorize! plan,
        with: PlanPolicy

      render jsonapi: plan
    end

    private

    attr_reader :plan

    def set_plan
      @plan = Plan.find params[:id]

      Current.resource = plan
    end

    def cache_key
      [:plans, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end
  end
end
