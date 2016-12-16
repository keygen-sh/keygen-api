module Api::V1
  class PlansController < Api::V1::BaseController
    before_action :set_plan, only: [:show]

    # GET /plans
    def index
      @plans = apply_scopes(Plan).all

      authorize @plans

      render json: @plans
    end

    # GET /plans/1
    def show
      render_not_found and return unless @plan

      authorize @plan

      render json: @plan
    end

    private

    def set_plan
      @plan = Plan.find_by id: params[:id]
    end
  end
end
