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
      if @license.present?
        CreateWebhookEventService.new(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license
        ).execute
      end

      render jsonapi: @license, meta: { valid: valid, detail: detail, constant: constant }
    end

    # POST /licenses/1/validate
    def validate_by_id
      authorize @license

      valid, detail, constant = LicenseValidationService.new(
        license: @license,
        scope: validation_params.dig(:meta, :scope)
      ).execute
      if @license.present?
        CreateWebhookEventService.new(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license
        ).execute
      end

      render jsonapi: @license, meta: { valid: valid, detail: detail, constant: constant }
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

      valid, detail, constant = LicenseValidationService.new(
        license: @license,
        scope: validation_params[:meta][:scope]
      ).execute
      if @license.present?
        CreateWebhookEventService.new(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license
        ).execute
      end

      render jsonapi: @license, meta: { valid: valid, detail: detail, constant: constant }
    end

    private

    def set_license
      # FIXME(ezekg) This allows the license to be looked up by ID or
      #              key, but this is pretty messy.
      id = params[:id] if params[:id] =~ UUID_REGEX # Only include when it's a UUID (else pg throws an err)
      key = params[:id]

      @license = current_account.licenses.where("id = ? OR key = ?", id, key).first
      raise ActiveRecord::RecordNotFound if @license.nil?
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
