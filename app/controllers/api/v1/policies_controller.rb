module Api::V1
  class PoliciesController < Api::V1::BaseController
    has_scope :product
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_policy, only: [:show, :update, :destroy]

    # GET /policies
    def index
      @policies = apply_scopes(@current_account.policies).all
      authorize @policies

      render json: @policies
    end

    # GET /policies/1
    def show
      render_not_found and return unless @policy

      authorize @policy

      render json: @policy
    end

    # POST /policies
    def create
      product = @current_account.products.find_by_hashid policy_params[:product]

      @policy = @current_account.policies.new policy_params.merge(product: product)
      authorize @policy

      if @policy.save
        render json: @policy, status: :created, location: v1_policy_url(@policy)
      else
        render_unprocessable_resource @policy
      end
    end

    # PATCH/PUT /policies/1
    def update
      render_not_found and return unless @policy

      authorize @policy

      if @policy.update(policy_params)
        render json: @policy
      else
        render_unprocessable_resource @policy
      end
    end

    # DELETE /policies/1
    def destroy
      render_not_found and return unless @policy

      authorize @policy

      @policy.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_policy
      @policy = @current_account.policies.find_by_hashid params[:id]
    end

    # Only allow a trusted parameter "white list" through.
    def policy_params
      params.require(:policy).permit :name, :price, :duration, :strict,
                                     :recurring, :floating, :use_pool,
                                     :product, :pool => []
    end
  end
end
