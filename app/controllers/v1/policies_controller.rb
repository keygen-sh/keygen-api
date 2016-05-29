class V1::PoliciesController < V1::ApiController
  before_action :set_policy, only: [:show, :update, :destroy]

  # GET /policies
  def index
    @policies = Policy.all

    render json: @policies
  end

  # GET /policies/1
  def show
    render json: @policy
  end

  # POST /policies
  def create
    @policy = Policy.new(policy_params)

    if @policy.save
      render json: @policy, status: :created, location: @policy
    else
      render json: @policy.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /policies/1
  def update
    if @policy.update(policy_params)
      render json: @policy
    else
      render json: @policy.errors, status: :unprocessable_entity
    end
  end

  # DELETE /policies/1
  def destroy
    @policy.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_policy
      @policy = Policy.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def policy_params
      params.require(:policy).permit(:name, :price, :duration, :strict, :recurring, :floating, :use_pool, :pool)
    end
end
