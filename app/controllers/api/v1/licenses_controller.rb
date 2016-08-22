module Api::V1
  class LicensesController < Api::V1::BaseController
    has_scope :policy
    has_scope :user
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:show, :update, :destroy]

    # GET /licenses
    def index
      @licenses = apply_scopes(@current_account.licenses).all
      authorize @licenses

      render json: @licenses
    end

    # GET /licenses/1
    def show
      render_not_found and return unless @license

      authorize @license

      render json: @license
    end

    # POST /licenses
    def create
      policy = @current_account.policies.find_by_hashid license_params[:policy]
      user = @current_account.users.find_by_hashid license_params[:user]

      @license = @current_account.licenses.new license_params.merge(policy: policy, user: user)
      authorize @license

      if @license.save
        render json: @license, status: :created, location: v1_license_url(@license)
      else
        render_unprocessable_resource @license
      end
    end

    # PATCH/PUT /licenses/1
    def update
      render_not_found and return unless @license

      authorize @license

      if @license.update(license_params)
        render json: @license
      else
        render_unprocessable_resource @license
      end
    end

    # DELETE /licenses/1
    def destroy
      render_not_found and return unless @license

      authorize @license

      @license.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_license
      @license = @current_account.licenses.find_by_hashid params[:id]
    end

    # Only allow a trusted parameter "white list" through.
    def license_params
      params.require(:license).permit :policy, :user, :active_machines => []
    end
  end
end
