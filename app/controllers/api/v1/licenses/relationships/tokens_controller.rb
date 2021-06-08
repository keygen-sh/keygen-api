# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # POST /licenses/1/tokens
    def generate
      authorize @license, :generate_token?

      kwargs = token_params.to_h.symbolize_keys.slice(
        :max_activations,
        :max_deactivations,
        :expiry
      )

      token = TokenGeneratorService.new(
        account: current_account,
        bearer: @license,
        **kwargs
      ).execute
      if token.valid?
        CreateWebhookEventService.new(
          event: "token.generated",
          account: current_account,
          resource: token
        ).execute

        render jsonapi: token
      else
        render_unprocessable_resource token
      end
    end

    # GET /licenses/1/tokens
    def index
      authorize @license, :list_tokens?

      # FIXME(ezekg) Skipping the policy scope here so that products can see
      #              tokens which belong to licenses they own. Current behavior
      #              is that non-admin bearers can only see their own tokens.
      #              The scoping is happening within the main app policy.
      @tokens = apply_scopes(@license.tokens)
      authorize @tokens

      render jsonapi: @tokens
    end

    # GET /licenses/1/tokens/1
    def show
      authorize @license, :show_token?

      @token = @license.tokens.find params[:id]

      render jsonapi: @token
    end

    private

    def set_license
      @license = FindByAliasService.new(current_account.licenses, params[:license_id] || params[:id], aliases: :key).call
      authorize @license, :show?

      Keygen::Store::Request.store[:current_resource] = @license
    end

    typed_parameters transform: true do
      options strict: true

      on :generate do
        param :data, type: :hash, optional: true do
          param :type, type: :string, inclusion: %w[token tokens]
          param :attributes, type: :hash do
            param :expiry, type: :datetime, allow_nil: true, optional: true, coerce: true
            param :max_activations, type: :integer, optional: true
            param :max_deactivations, type: :integer, optional: true
          end
        end
      end
    end
  end
end
