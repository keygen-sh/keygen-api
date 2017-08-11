module Api::V1::Licenses::Actions
  class ValidationsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[validate_by_key]

    # GET /licenses/1/validate
    def validate_by_id
      @license = current_account.licenses.find params[:id]
      authorize @license

      valid, detail = LicenseValidationService.new(license: @license).execute
      if @license.present?
        CreateWebhookEventService.new(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license
        ).execute
      end

      render_meta valid: valid, detail: detail
    end

    # POST /licenses/validate-key
    def validate_by_key
      skip_authorization

      @license = LicenseKeyLookupService.new(
        account: current_account,
        encrypted: validation_params[:meta][:encrypted] == true,
        key: validation_params[:meta][:key],
        scope: validation_params[:meta][:scope]
      ).execute

      valid, detail = LicenseValidationService.new(license: @license).execute
      if @license.present?
        CreateWebhookEventService.new(
          event: valid ? "license.validation.succeeded" : "license.validation.failed",
          account: current_account,
          resource: @license
        ).execute
      end

      render_meta valid: valid, detail: detail
    end

    typed_parameters do
      options strict: true

      on :validate_by_key do
        param :meta, type: :hash do
          param :key, type: :string, allow_blank: false
          param :encrypted, type: :boolean, optional: true
          param :scope, type: :hash, optional: true do
            param :product, type: :string, optional: true
          end
        end
      end
    end
  end
end
