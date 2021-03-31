# frozen_string_literal: true

module Api::V1
  class PlansController < Api::V1::BaseController
    before_action :set_plan, only: [:show]

    # GET /plans
    def index
      authorize Plan

      json = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        plans = apply_scopes(Plan.visible).reorder('price ASC NULLS FIRST')
        data = JSONAPI::Serializable::Renderer.new.render(plans, {
          expose: { url_helpers: Rails.application.routes.url_helpers },
          class: {
            Account: SerializableAccount,
            Plan: SerializablePlan,
            Error: SerializableError
          }
        })

        data
      end

      render json: json
    end

    # GET /plans/1
    def show
      authorize @plan

      render jsonapi: @plan
    end

    private

    def set_plan
      @plan = Plan.find params[:id]
    end

    def cache_key
      [:plans, Digest::SHA2.hexdigest(request.query_string), CACHE_KEY_VERSION].join ":"
    end
  end
end
