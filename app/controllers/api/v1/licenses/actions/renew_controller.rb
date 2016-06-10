module Api::V1::Licenses::Actions
  class RenewController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:renew_license]

    # POST /licenses/1/actions/renew
    def renew_license
      authorize @license

      new_expiry =
        if @license.policy.duration.nil?
          nil
        else
          Time.now + @license.policy.duration
        end

      if @license.update(expiry: new_expiry)
        render json: @license
      else
        render json: @license, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    private

    def set_license
      @license = @current_account.licenses.find_by_hashid params[:license_id]
    end
  end
end
