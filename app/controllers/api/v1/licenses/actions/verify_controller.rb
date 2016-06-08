module Api::V1::Licenses::Actions
  class VerifyController < Api::V1::BaseController
    scope_by_subdomain

    before_action :set_license, only: [:verify]

    # accessible_by_admin_or_resource_owner :verify

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
