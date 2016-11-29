module Api::V1
  class LicensesController < Api::V1::BaseController
    has_scope :product
    has_scope :policy
    has_scope :user

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:show, :update, :destroy]

    # GET /licenses
    def index
      @licenses = policy_scope apply_scopes(current_account.licenses).all
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
      policy = current_account.policies.find_by_hashid license_parameters[:policy]
      user = current_account.users.find_by_hashid license_parameters[:user]

      @license = current_account.licenses.new license_parameters.merge(
        policy: policy,
        user: user
      )
      authorize @license

      if @license.save
        CreateWebhookEventService.new(
          event: "license.created",
          account: current_account,
          resource: @license
        ).execute

        render json: @license, status: :created, location: v1_license_url(@license)
      else
        render_unprocessable_resource @license
      end
    end

    # PATCH/PUT /licenses/1
    def update
      render_not_found and return unless @license

      authorize @license

      if @license.update(license_parameters)
        CreateWebhookEventService.new(
          event: "license.updated",
          account: current_account,
          resource: @license
        ).execute

        render json: @license
      else
        render_unprocessable_resource @license
      end
    end

    # DELETE /licenses/1
    def destroy
      render_not_found and return unless @license

      authorize @license

      CreateWebhookEventService.new(
        event: "license.deleted",
        account: current_account,
        resource: @license
      ).execute

      @license.destroy
    end

    private

    attr_reader :parameters

    def set_license
      @license = current_account.licenses.find_by_hashid params[:id]
    end

    def license_parameters
      parameters[:license]
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :create do
          param :license, type: :hash do
            param :policy, type: :string
            param :user, type: :string, optional: true
            param :metadata, type: :hash, optional: true
          end
        end

        on :update do
          param :license, type: :hash do
            param :expiry, type: :string, optional: true
            param :metadata, type: :hash, optional: true
          end
        end
      end
    end
  end
end
