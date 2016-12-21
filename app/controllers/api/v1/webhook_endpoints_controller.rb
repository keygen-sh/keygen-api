module Api::V1
  class WebhookEndpointsController < Api::V1::BaseController
    before_action :scope_to_current_account!
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
      authorize @endpoint

      render json: @endpoint
    end

    # POST /webhook-endpoints
    def create
      @endpoint = current_account.webhook_endpoints.new endpoint_parameters
      authorize @endpoint

      if @endpoint.save
        render json: @endpoint, status: :created, location: v1_account_webhook_endpoint_url(@endpoint.account, @endpoint)
      else
        render_unprocessable_resource @endpoint
      end
    end

    # PATCH/PUT /webhook-endpoints/1
    def update
      authorize @endpoint

      if @endpoint.update(endpoint_parameters)
        render json: @endpoint
      else
        render_unprocessable_resource @endpoint
      end
    end

    # DELETE /webhook-endpoints/1
    def destroy
      authorize @endpoint

      @endpoint.destroy
    end

    private

    attr_reader :parameters

    def set_endpoint
      @endpoint = current_account.webhook_endpoints.find params[:id]
    end

    def endpoint_parameters
      parameters[:endpoint]
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :create do
          param :endpoint, type: :hash do
            param :url, type: :string
          end
        end

        on :update do
          param :endpoint, type: :hash do
            param :url, type: :string, optional: true
          end
        end
      end
    end
  end
end
