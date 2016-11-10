module Api::V1::Licenses::Actions
  class ValidationsController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!

    # GET /licenses/1/actions/validate
    def validate_by_id
      @license = current_account.licenses.find_by_hashid params[:license_id]
      authorize @license

      render_meta is_valid: LicenseValidationService.new(license: @license).execute
    end

    # POST /licenses/actions/validate-key
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
