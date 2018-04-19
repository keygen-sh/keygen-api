module Api::V1::Licenses::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # POST /licenses/1/tokens
    def generate
      authorize @license, :generate_token?

      token = TokenGeneratorService.new(
        account: current_account,
        bearer: @license,
        expiry: false
      ).execute

      render jsonapi: token
    end

    # GET /licenses/1/tokens
    def index
      authorize @license, :list_tokens?

      # FIXME(ezekg) Skipping the policy scope here so that products can see
      #              tokens which belong to licenses they own. Current behavior
      #              is that non-admin bearers can only see their own tokens.
      #              The scoping is happening within the main app policy.
      @tokens = apply_scopes(@license.tokens).all
      authorize @tokens

      render jsonapi: @tokens
    end

    # GET /licenses/1/tokens/1
    def show
      authorize @license, :view_token?

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
