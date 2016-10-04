module Api::V1
  class WebhooksController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_webhook, only: [:show, :update, :destroy]

    # GET /webhooks
    def index
      @webhooks = policy_scope apply_scopes(@current_account.webhooks).all
      authorize @webhooks

      render json: @webhooks
    end

    # GET /webhooks/1
    def show
      render_not_found and return unless @webhook

      authorize @webhook

      render json: @webhook
    end

    # POST /webhooks
    def create
      @webhook = @current_account.webhooks.new webhook_params
      authorize @webhook

      if @webhook.save
        render json: @webhook, status: :created, location: v1_webhook_url(@webhook)
      else
        render_unprocessable_resource @webhook
      end
    end

    # PATCH/PUT /webhooks/1
    def update
      render_not_found and return unless @webhook

      authorize @webhook

      if @webhook.update(webhook_params)
        render json: @webhook
      else
        render_unprocessable_resource @webhook
      end
    end

    # DELETE /webhooks/1
    def destroy
      render_not_found and return unless @webhook

      authorize @webhook

      @webhook.destroy
    end

    private

    def set_webhook
      @webhook = Webhook.find_by_hashid params[:id]
    end

    def webhook_params
      params.require(:webhook).permit :url
    end
  end
end
