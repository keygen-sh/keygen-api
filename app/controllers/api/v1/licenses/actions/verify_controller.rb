module Api::V1::Licenses::Actions
  class VerifyController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:verify_license]

    # GET /licenses/1/actions/verify
    def verify_license
      authorize @license

      render_meta is_valid: @license.license_valid?
    end

    private

    def set_license
      @license = @current_account.licenses.find_by_hashid params[:license_id]
      @license || render_not_found
    end
  end
end
