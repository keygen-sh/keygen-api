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

      params.require :key

      @license = LicenseKeyLookupService.new(
        account: current_account,
        encrypted: params[:encrypted] == true,
        key: params[:key],
      ).execute

      render_meta is_valid: LicenseValidationService.new(license: @license).execute
    end
  end
end
