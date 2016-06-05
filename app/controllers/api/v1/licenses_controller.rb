module Api::V1
  class LicensesController < ApiController
    before_action :set_license, only: [:show, :update, :destroy]

    # GET /licenses
    def index
      @licenses = License.all

      render json: @licenses
    end

    # GET /licenses/1
    def show
      render json: @license
    end

    # POST /licenses
    def create
      @license = License.new(license_params)

      if @license.save
        render json: @license, status: :created, location: v1_license_url(@license)
      else
        render json: @license, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # PATCH/PUT /licenses/1
    def update
      if @license.update(license_params)
        render json: @license
      else
        render json: @license, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # DELETE /licenses/1
    def destroy
      @license.destroy
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_license
        @license = License.find_by_hashid(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def license_params
        params.require(:license).permit(:key, :expiry, :activations, :policy, :user, :active_machines => [])
      end
  end
end
