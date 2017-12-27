module Api::V1::Licenses::Actions
  class ValidationsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[validate_by_key]

    # GET /licenses/1/validate
    def validate_by_id
      @license = current_account.licenses.find params[:id]
      authorize @license

      valid, detail, constant = LicenseValidationService.new(license: @license).execute
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
        encrypted: validation_params[:meta][:encrypted] == true,
        key: validation_params[:meta][:key]
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

    typed_parameters do
      options strict: true

      on :validate_by_key do
        param :meta, type: :hash do
          param :key, type: :string, allow_blank: false
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
