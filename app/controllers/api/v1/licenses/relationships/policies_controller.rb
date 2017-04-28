module Api::V1::Licenses::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/policy
    def show
      @policy = @license.policy
      authorize @policy

      render jsonapi: @policy
    end

    private

    def set_license
      @license = current_account.licenses.find params[:license_id]
      authorize @license, :show?
    end
  end
end
