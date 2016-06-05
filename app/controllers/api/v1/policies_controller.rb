module Api::V1
  class PoliciesController < ApiController
    before_action :set_policy, only: [:show, :update, :destroy]

    accessible_by_admin :index, :show, :create, :update, :destroy

    # GET /policies
    def index
      @policies = @current_account.policies.all

      render json: @policies
    end

    # GET /policies/1
    def show
      render json: @policy
    end

    # POST /policies
    def create
      @policy = Policy.new policy_params.merge(account_id: @current_account.id)

      if @policy.save
        render json: @policy, status: :created, location: v1_policy_url(@policy)
      else
        render json: @policy, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # PATCH/PUT /policies/1
    def update
      if @policy.update(policy_params)
        render json: @policy
      else
        render json: @policy, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # DELETE /policies/1
    def destroy
      @policy.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_policy
      @policy = @current_account.policies.find_by_hashid params[:id]
    end

    # Only allow a trusted parameter "white list" through.
    def policy_params
      params.require(:policy).permit :name, :price, :duration, :strict, :recurring, :floating, :use_pool, :account, :pool => []
    end
  end
end
