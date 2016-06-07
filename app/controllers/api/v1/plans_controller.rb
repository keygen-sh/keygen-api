module Api::V1
  class PlansController < BaseController
    before_action :set_plan, only: [:show, :update, :destroy]

    # accessible_by_nobody :create, :update, :destroy
    # accessible_by_public :index, :show

    # GET /plans
    def index
      @plans = Plan.all

      render json: @plans
    end

    # GET /plans/1
    def show
      render json: @plan
    end

    # POST /plans
    def create
      @plan = Plan.new plan_params

      if @plan.save
        render json: @plan, status: :created, location: v1_plan_url(@plan)
      else
        render json: @plan, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # PATCH/PUT /plans/1
    def update
      if @plan.update(plan_params)
        render json: @plan
      else
        render json: @plan, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # DELETE /plans/1
    def destroy
      @plan.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_plan
      @plan = Plan.find_by_hashid params[:id]
    end

    # Only allow a trusted parameter "white list" through.
    def plan_params
      params.require(:plan).permit :name, :price, :max_products, :max_users, :max_policies, :max_licenses
    end
  end
end
