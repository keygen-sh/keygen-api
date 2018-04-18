module Api::V1::Licenses::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # POST /licenses/1/tokens
    def generate
      authorize @license

      token = TokenGeneratorService.new(
        account: current_account,
        bearer: @license,
        expiry: false
      ).execute

      render jsonapi: token
    end

    # GET /licenses/1/tokens
    def index
      authorize @license, :show?

      @tokens = policy_scope apply_scopes(@license.tokens).all
      authorize @tokens

      render jsonapi: @tokens
    end

    # GET /licenses/1/tokens/1
    def show
      authorize @license

      @token = @license.tokens.find params[:id]
      authorize @token

      render jsonapi: @token
    end

    private

    def set_license
      @license = current_account.licenses.find params[:license_id] || params[:id]
    end
  end
end
