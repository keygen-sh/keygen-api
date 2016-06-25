module Api::V1::Licenses::Actions
  class PermitController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:renew, :revoke, :verify]

    # POST /licenses/1/actions/renew
    def renew
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

    # POST /licenses/1/actions/revoke
    def revoke
      authorize @license

      @license.destroy
    end

    # GET /licenses/1/actions/verify
    def verify
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
