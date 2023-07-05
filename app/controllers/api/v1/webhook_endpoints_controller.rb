# frozen_string_literal: true

module Api::V1
  class WebhookEndpointsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_endpoint, only: [:show, :update, :destroy]

    def index
      endpoints = apply_pagination(authorized_scope(apply_scopes(current_account.webhook_endpoints)))
      authorize! endpoints

      render jsonapi: endpoints
    end

    def show
      authorize! endpoint

      render jsonapi: endpoint
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[webhookEndpoint webhookEndpoints webhook-endpoint webhook-endpoints webhook_endpoint webhook_endpoints] }
        param :attributes, type: :hash do
          param :url, type: :string
          param :subscriptions, type: :array, optional: true do
            items type: :string
          end
          param :signature_algorithm, type: :string, optional: true
        end
        param :relationships, type: :hash, optional: true do
          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :uuid
              end
            end
          end
        end
      end
    }
    def create
      endpoint = current_account.webhook_endpoints.new(api_version: current_api_version, **webhook_endpoint_params)
      authorize! endpoint

      if endpoint.save
        render jsonapi: endpoint, status: :created, location: v1_account_webhook_endpoint_url(endpoint.account, endpoint)
      else
        render_unprocessable_resource endpoint
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[webhookEndpoint webhookEndpoints webhook-endpoint webhook-endpoints webhook_endpoint webhook_endpoints] }
        param :id, type: :uuid, optional: true, noop: true
        param :attributes, type: :hash do
          param :url, type: :string, optional: true
          param :subscriptions, type: :array, optional: true do
            items type: :string
          end
          param :api_version, type: :string, inclusion: { in: RequestMigrations.supported_versions }, optional: true
          param :signature_algorithm, type: :string, optional: true
        end
      end
    }
    def update
      authorize! endpoint

      if endpoint.update(webhook_endpoint_params)
        render jsonapi: endpoint
      else
        render_unprocessable_resource endpoint
      end
    end

    def destroy
      authorize! endpoint

      endpoint.destroy_async
    end

    private

    attr_reader :endpoint

    def set_endpoint
      scoped_endpoints = authorized_scope(current_account.webhook_endpoints)

      @endpoint = scoped_endpoints.find(params[:id])

      Current.resource = endpoint
    end
  end
end
