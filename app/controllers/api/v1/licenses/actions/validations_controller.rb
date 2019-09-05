# frozen_string_literal: true

module Api::V1::Licenses::Actions
  class ValidationsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[validate_by_key]
    before_action :set_license, only: %i[quick_validate_by_id validate_by_id]

    # GET /licenses/1/validate
    def quick_validate_by_id
      authorize @license

      valid, detail, constant = LicenseValidationService.new(license: @license, scope: false).execute
      meta = {
        ts: Time.current, # Included so customer has a signed ts to utilize elsewhere
        valid: valid,
        detail: detail,
        constant: constant,
      }

      if @license.present?
        Rails.logger.info "[license.quick-validate] request_id=#{request.uuid} license_id=#{@license.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant}"

        CreateWebhookEventService.new(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license,
          meta: meta
        ).execute
      end

      render jsonapi: @license, meta: meta
    end

    # POST /licenses/1/validate
    def validate_by_id
      authorize @license

      valid, detail, constant = LicenseValidationService.new(license: @license, scope: validation_params.dig(:meta, :scope)).execute
      meta = {
        ts: Time.current,
        valid: valid,
        detail: detail,
        constant: constant,
      }

      if @license.present?
        Rails.logger.info "[license.validate] request_id=#{request.uuid} license_id=#{@license.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant}"

        CreateWebhookEventService.new(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license,
          meta: meta
        ).execute
      end

      render jsonapi: @license, meta: meta
    end

    # POST /licenses/validate-key
    def validate_by_key
      skip_authorization

      @license = LicenseKeyLookupService.new(
        account: current_account,
        key: validation_params[:meta][:key],
        # Since we've added new encryption schemes, we only want to alter
        # the lookup for legacy encrypted licenses.
        legacy_encrypted: validation_params[:meta][:legacy_encrypted] == true ||
                          validation_params[:meta][:encrypted] == true
      ).execute

      valid, detail, constant = LicenseValidationService.new(license: @license, scope: validation_params[:meta][:scope]).execute
      meta = {
        ts: Time.current,
        valid: valid,
        detail: detail,
        constant: constant,
      }

      if @license.present?
        Rails.logger.info "[license.validate-key] request_id=#{request.uuid} license_id=#{@license.id} validation_valid=#{valid} validation_detail=#{detail} validation_code=#{constant}"

        CreateWebhookEventService.new(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license,
          meta: meta
        ).execute
      end

      render jsonapi: @license, meta: meta
    end

    private

    def set_license
      @license = current_account.licenses.find params[:id]
    end

    typed_parameters do
      options strict: true

      on :validate_by_id do
        param :meta, type: :hash, optional: true do
          param :scope, type: :hash, optional: true do
            param :product, type: :string, optional: true
            param :policy, type: :string, optional: true
            param :machine, type: :string, optional: true
            param :fingerprint, type: :string, optional: true
          end
        end
      end

      on :validate_by_key do
        param :meta, type: :hash do
          param :key, type: :string, allow_blank: false
          param :legacy_encrypted, type: :boolean, optional: true
          param :encrypted, type: :boolean, optional: true
          param :scope, type: :hash, optional: true do
            param :product, type: :string, optional: true
            param :policy, type: :string, optional: true
            param :machine, type: :string, optional: true
            param :fingerprint, type: :string, optional: true
          end
        end
      end
    end
  end
end
