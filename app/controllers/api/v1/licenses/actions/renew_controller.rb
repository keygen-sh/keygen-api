module Api::V1::Licenses::Actions
  class RenewController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:renew_license]

    # POST /licenses/1/actions/renew
    def renew_license
      authorize @license

      if @license.policy.duration.nil?
        render_unprocessable_entity({
          detail: "cannot be renewed because it does not expire",
          source: {
            pointer: "/data/attributes/expiry"
          }
        })
      elsif @license.update(expiry: Time.now + @license.policy.duration)
        render json: @license
      else
        render_unprocessable_resource @license
      end
    end

    private

    def set_license
      @license = @current_account.licenses.find_by_hashid params[:license_id]
      @license || render_not_found
    end
  end
end
