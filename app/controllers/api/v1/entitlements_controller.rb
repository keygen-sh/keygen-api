# frozen_string_literal: true

module Api::V1
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_entitlement, only: [:show, :update, :destroy]

    def index
      @entitlements = policy_scope apply_scopes(current_account.entitlements)
      authorize @entitlements

      render jsonapi: @entitlements
    end

    def show
      authorize @entitlement

      render jsonapi: @entitlement
    end

    def create
      @entitlement = current_account.entitlements.new entitlement_params
      authorize @entitlement

      if @entitlement.save
        CreateWebhookEventService.new(
          event: "entitlement.created",
          account: current_account,
          resource: @entitlement
        ).execute

        render jsonapi: @entitlement, status: :created, location: v1_account_entitlement_url(@entitlement.account, @entitlement)
      else
        render_unprocessable_resource @entitlement
      end
    end

    def update
      authorize @entitlement

      if @entitlement.update(entitlement_params)
        CreateWebhookEventService.new(
          event: "entitlement.updated",
          account: current_account,
          resource: @entitlement
        ).execute

        render jsonapi: @entitlement
      else
        render_unprocessable_resource @entitlement
      end
    end

    def destroy
      authorize @entitlement

      CreateWebhookEventService.new(
        event: "entitlement.deleted",
        account: current_account,
        resource: @entitlement
      ).execute

      @entitlement.destroy
    end

    private

    def set_entitlement
      @entitlement = current_account.entitlements.find(params[:id])

      Keygen::Store::Request.store[:current_resource] = @entitlement
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[entitlement entitlements]
          param :attributes, type: :hash do
            param :name, type: :string
            param :code, type: :string
            param :metadata, type: :hash, optional: true
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[entitlement entitlements]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :code, type: :string, optional: true
            param :metadata, type: :hash, optional: true
          end
        end
      end
    end
  end
end
