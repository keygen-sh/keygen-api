module Api::V1::Licenses
  class ValidationsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!

    # GET /licenses/1/validate
    def validate_by_id
      @license = current_account.licenses.find params[:id]
      authorize @license

      render_meta is_valid: LicenseValidationService.new(license: @license).execute
    end

    # POST /licenses/validate-key
    def validate_by_key
      skip_authorization

      @license = LicenseKeyLookupService.new(
        account: current_account,
        encrypted: validation_params[:meta][:encrypted] == true,
        key: validation_params[:meta][:key],
      ).execute

      render_meta is_valid: LicenseValidationService.new(license: @license).execute
    end

    typed_parameters do
      options strict: true

      on :validate_by_key do
        param :meta, type: :hash do
          param :key, type: :string
          param :encrypted, type: :boolean, optional: true
        end
      end
    end
  end
end
