module Api::V1::Licenses::Actions
  class VerifyController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:verify]

    # GET /licenses/1/actions/verify
    def verify
      render json: @license, serializer: LicenseValiditySerializer
    end

    private

    def set_license
      @license = @current_account.licenses.find_by_hashid params[:license_id]
    end
  end
end
