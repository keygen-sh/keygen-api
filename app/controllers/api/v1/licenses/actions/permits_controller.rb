module Api::V1::Licenses::Actions
  class PermitsController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:renew, :revoke, :verify]

    # POST /licenses/1/actions/renew
    def renew
      render_not_found and return unless @license

      authorize @license

      if @license.policy.duration.nil?
        render_unprocessable_entity({
          detail: "cannot be renewed because it does not expire",
          source: {
            pointer: "/data/attributes/expiry"
          }
        })
      elsif @license.update(expiry: @license.expiry + @license.policy.duration)
        render json: @license
      else
        render_unprocessable_resource @license
      end
    end

    # POST /licenses/1/actions/revoke
    def revoke
      render_not_found and return unless @license

      authorize @license

      @license.destroy
    end

    # GET /licenses/1/actions/verify
    def verify
      render_not_found and return unless @license

      authorize @license

      render_meta is_valid: @license.license_valid?
    end

    private

    def set_license
      @license = @current_account.licenses.find_by_hashid params[:license_id]
    end
  end
end
