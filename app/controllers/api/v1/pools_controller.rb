module Api::V1
  class PoolsController < Api::V1::BaseController
    has_scope :policy
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :set_pool, only: [:show, :update, :destroy]

    # GET /pools
    def index
      @pools = apply_scopes(Pool).all
      authorize @pools

      render json: @pools
    end

    # GET /pools/1
    def show
      render_not_found and return unless @pool

      authorize @pool

      render json: @pool
    end

    # POST /pools
    def create
      policy = @current_account.licenses.find_by_hashid pool_params[:policy]

      @pool = @current_account.pools.new pool_params.merge(policy: policy)
      authorize @pool

      if @pool.save
        render json: @pool, status: :created, location: v1_pool_url(@pool)
      else
        render_unprocessable_resource @pool
      end
    end

    # PATCH/PUT /pools/1
    def update
      render_not_found and return unless @pool

      authorize @pool

      if @pool.update(pool_params)
        render json: @pool
      else
        render_unprocessable_resource @pool
      end
    end

    # DELETE /pools/1
    def destroy
      render_not_found and return unless @pool

      authorize @pool

      @pool.destroy
    end

    private

    def set_pool
      @pool = Pool.find_by_hashid params[:id]
    end

    def pool_params
      permitted_params
    end

    attr_accessor :permitted_params

    def permitted_params
      @permitted_params ||= Proc.new do
        schema = params.require(:pool).tap do |param|
          permits = []

          if action_name == "create"
            permits << :policy
          end

          permits << :key

          param.permit *permits
        end.to_unsafe_hash

        schema
      end.call
    end
  end
end
