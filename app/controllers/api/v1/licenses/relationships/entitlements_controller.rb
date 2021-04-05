# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class EntitlementsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    def index
      authorize @license, :list_entitlements?

      @entitlements = policy_scope apply_scopes(@license.entitlements)
      authorize @entitlements

      render jsonapi: @entitlements
    end

    def show
      authorize @license, :show_entitlement?
      @entitlement = @license.entitlements.find params[:id]

      render jsonapi: @entitlement
    end

    def attach
      authorize @license, :attach_entitlement?
      @license_entitlements = @license.license_entitlements

      entitlements = entitlement_params.fetch(:data).map do |entitlement|
        entitlement.merge(account_id: current_account.id)
      end

      @license_entitlements.transaction do
        attached = @license_entitlements.create!(entitlements)

        attached.each do |license_entitlement|
          CreateWebhookEventService.new(
            event: 'license.entitlement.attached',
            account: current_account,
            resource: license_entitlement.entitlement
          ).execute
        end
      end
    end

    def detach
      authorize @license, :detach_entitlement?
      @license_entitlements = @license.license_entitlements

      entitlement_ids = entitlement_params.fetch(:data).collect { |e| e[:entitlement_id] }
      entitlements = @license_entitlements.where(entitlement_id: entitlement_ids)

      if entitlements.size != entitlement_ids.size
        entitlement_ids_not_found = entitlement_ids - entitlements.collect(&:entitlement_id)

        entitlements.raise_record_not_found_exception!(
          entitlement_ids_not_found,
          entitlements.size,
          entitlement_ids.size
        )
      end

      @license_entitlements.transaction do
        detached = @license_entitlements.delete(entitlements)

        detached.each do |license_entitlement|
          CreateWebhookEventService.new(
            event: 'license.entitlement.detached',
            account: current_account,
            resource: license_entitlement.entitlement
          ).execute
        end
      end
    end

    private

    def set_license
      @license = FindByAliasService.new(current_account.licenses, params[:license_id], aliases: :key).call

      Keygen::Store::Request.store[:current_resource] = @license
    end

    typed_parameters do
      options strict: true

      on :attach do
        param :data, type: :array do
          items type: :hash do
            param :type, type: :string, inclusion: %w[entitlement entitlements], transform: -> (k, v) { [] }
            param :id, type: :string, transform: -> (k, v) {
              [:entitlement_id, v]
            }
          end
        end
      end

      on :detach do
        param :data, type: :array do
          items type: :hash do
            param :type, type: :string, inclusion: %w[entitlement entitlements], transform: -> (k, v) { [] }
            param :id, type: :string, transform: -> (k, v) {
              [:entitlement_id, v]
            }
          end
        end
      end
    end
  end
end
