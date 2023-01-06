# frozen_string_literal: true

module Api::V1::Products::Relationships
  class TokensController < Api::V1::BaseController
    supports_environment

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      tokens = apply_pagination(authorized_scope(apply_scopes(product.tokens)))
      authorize! tokens,
        with: Products::TokenPolicy

      render jsonapi: tokens
    end

    def show
      token = product.tokens.find(params[:id])
      authorize! token,
        with: Products::TokenPolicy

      render jsonapi: token
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, optional: true do
        param :type, type: :string, inclusion: { in: %w[token tokens] }
        param :attributes, type: :hash do
          param :expiry, type: :time, allow_nil: true, optional: true, coerce: true
          param :name, type: :string, allow_nil: true, optional: true

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_account.ent? && current_bearer&.has_role?(:admin, :product) } do
              items type: :string
            end
          end
        end
      end
    }
    def create
      authorize! with: Products::TokenPolicy

      kwargs = token_params.to_h.symbolize_keys.slice(
        :permissions,
        :expiry,
        :name,
      )

      token = TokenGeneratorService.call(
        account: current_account,
        bearer: product,
        **kwargs,
      )

      BroadcastEventService.call(
        event: 'token.generated',
        account: current_account,
        resource: token,
      )

      render jsonapi: token
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = scoped_products.find(params[:product_id])

      Current.resource = product
    end
  end
end
