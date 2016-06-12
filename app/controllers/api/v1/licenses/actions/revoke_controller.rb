module Api::V1::Licenses::Actions
  class RevokeController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:revoke_license]

    # POST /licenses/1/actions/revoke
    def revoke_license
      authorize @license

      @license.destroy
    end

    private

    def set_license
      @license = @current_account.licenses.find_by_hashid params[:license_id]
      @license || render_not_found
    end
  end
end
