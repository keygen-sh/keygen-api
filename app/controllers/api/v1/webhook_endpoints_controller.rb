module Api::V1
  class WebhookEndpointsController < Api::V1::BaseController
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_endpoint, only: [:show, :update, :destroy]

    # GET /webhook-endpoints
    def index
      @endpoints = policy_scope apply_scopes(current_account.webhook_endpoints).all
      authorize @endpoints

      render json: @endpoints
    end

    # GET /webhook-endpoints/1
    def show
      render_not_found and return unless @endpoint

      authorize @endpoint

      render json: @endpoint
    end

    # POST /webhook-endpoints
    def create
      @endpoint = current_account.webhook_endpoints.new endpoint_params
      authorize @endpoint

      if @endpoint.save
        render json: @endpoint, status: :created, location: v1_webhook_endpoint_url(@endpoint)
      else
        render_unprocessable_resource @endpoint
      end
    end

    # PATCH/PUT /webhook-endpoints/1
    def update
      render_not_found and return unless @endpoint

      authorize @endpoint

      if @endpoint.update(endpoint_params)
        render json: @endpoint
      else
        render_unprocessable_resource @endpoint
      end
    end

    # DELETE /webhook-endpoints/1
    def destroy
      render_not_found and return unless @endpoint

      authorize @endpoint

      @endpoint.destroy
    end

    private

    def set_endpoint
      @endpoint = WebhookEndpoint.find_by_hashid params[:id]
    end

    def endpoint_params
      params.require(:endpoint).permit :url
    end
  end
end
