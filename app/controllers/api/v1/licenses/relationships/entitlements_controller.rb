# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def index
      @entitlements = policy_scope apply_scopes(@license.license_entitlements)
      authorize @entitlements

      render jsonapi: @entitlements
    end

    def show
      @entitlement = @license.license_entitlements.find params[:id]
      authorize @entitlement

      render jsonapi: @entitlement
    end

    def create
      @entitlement = @license.license_entitlements.new entitlement_params.merge(account: current_account)
      authorize @entitlement

      if @entitlement.save
        CreateWebhookEventService.new(
          event: 'license.entitlement.created',
          account: current_account,
          resource: @entitlement
        ).execute

        render jsonapi: @entitlement, status: :created, location: v1_account_license_entitlement_url(@entitlement.account, @entitlement.license, @entitlement)
      else
        render_unprocessable_resource @entitlement
      end
    end

    def destroy
      @entitlement = @license.license_entitlements.find params[:id]
      authorize @entitlement

      CreateWebhookEventService.new(
        event: 'license.entitlement.deleted',
        account: current_account,
        resource: @entitlement
      ).execute

      @entitlement.destroy
    end

    private

    def set_license
      @license = FindByAliasService.new(current_account.licenses, params[:license_id], aliases: :key).call

      Keygen::Store::Request.store[:current_resource] = @license
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[license.entitlement license.entitlements]
          param :relationships, type: :hash do
            param :entitlement, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[entitlement entitlements]
                param :id, type: :string
              end
            end
          end
        end
      end
    end
  end
end
