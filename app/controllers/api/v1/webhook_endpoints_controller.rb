# frozen_string_literal: true

module Api::V1
  class WebhookEndpointsController < Api::V1::BaseController
    prepend_before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_endpoint, only: [:show, :update, :destroy]

    # GET /webhook-endpoints
    def index
      @endpoints = policy_scope apply_scopes(current_account.webhook_endpoints)
      authorize @endpoints

      render jsonapi: @endpoints
    end

    # GET /webhook-endpoints/1
    def show
      authorize @endpoint

      render jsonapi: @endpoint
    end

    # POST /webhook-endpoints
    def create
      @endpoint = current_account.webhook_endpoints.new webhook_endpoint_params
      authorize @endpoint

      if @endpoint.save
        render jsonapi: @endpoint, status: :created, location: v1_account_webhook_endpoint_url(@endpoint.account, @endpoint)
      else
        render_unprocessable_resource @endpoint
      end
    end

    # PATCH/PUT /webhook-endpoints/1
    def update
      authorize @endpoint

      if @endpoint.update(webhook_endpoint_params)
        render jsonapi: @endpoint
      else
        render_unprocessable_resource @endpoint
      end
    end

    # DELETE /webhook-endpoints/1
    def destroy
      authorize @endpoint

      @endpoint.destroy_async
    end

    private

    def set_endpoint
      @endpoint = current_account.webhook_endpoints.find params[:id]
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[webhookEndpoint webhookEndpoints webhook-endpoint webhook-endpoints webhook_endpoint webhook_endpoints]
          param :attributes, type: :hash do
            param :url, type: :string
            param :subscriptions, type: :array, optional: true do
              items type: :string
            end
            param :signature_algorithm, type: :string, optional: true
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[webhookEndpoint webhookEndpoints webhook-endpoint webhook-endpoints webhook_endpoint webhook_endpoints]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :url, type: :string, optional: true
            param :subscriptions, type: :array, optional: true do
              items type: :string
            end
            param :signature_algorithm, type: :string, optional: true
          end
        end
      end
    end
  end
end
