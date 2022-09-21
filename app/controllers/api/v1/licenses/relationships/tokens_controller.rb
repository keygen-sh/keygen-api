# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    authorize :license

    def index
      tokens = apply_pagination(authorized_scope(apply_scopes(license.tokens)))
      authorize! tokens,
        with: Licenses::TokenPolicy

      render jsonapi: tokens
    end

    def show
      token = license.tokens.find(params[:id])
      authorize! token,
        with: Licenses::TokenPolicy

      render jsonapi: token
    end

    def create
      authorize! with: Licenses::TokenPolicy

      kwargs = token_params.to_h.symbolize_keys.slice(
        :max_activations,
        :max_deactivations,
        :permissions,
        :expiry,
        :name,
      )

      token = TokenGeneratorService.call(
        account: current_account,
        bearer: license,
        **kwargs,
      )

      if token.valid?
        BroadcastEventService.call(
          event: 'token.generated',
          account: current_account,
          resource: token,
        )

        render jsonapi: token
      else
        render_unprocessable_resource token
      end
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scope: scoped_licenses, identifier: params[:license_id], aliases: :key)

      Current.resource = license
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :create do
        param :data, type: :hash, optional: true do
          param :type, type: :string, inclusion: %w[token tokens]
          param :attributes, type: :hash do
            param :expiry, type: :datetime, allow_nil: true, optional: true, coerce: true
            param :name, type: :string, allow_nil: true, optional: true
            param :max_activations, type: :integer, optional: true
            param :max_deactivations, type: :integer, optional: true
            if current_account.ent? && current_bearer&.has_role?(:admin, :product)
              param :permissions, type: :array, optional: true do
                items type: :string
              end
            end
          end
        end
      end
    end
  end
end
