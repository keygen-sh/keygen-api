# frozen_string_literal: true

module Api::V1::Products::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      tokens = apply_pagination(authorized_scope(apply_scopes(product.tokens)).preload(:account, :permissions, bearer: { role: :permissions }))
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
        param :attributes, type: :hash, optional: true do
          param :expiry, type: :time, allow_nil: true, optional: true, coerce: true
          param :name, type: :string, allow_nil: true, optional: true

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :product, :environment) } do
              items type: :string
            end
          end
        end
        param :relationships, type: :hash, optional: true do
          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :uuid
              end
            end
          end
        end
      end
    }
    def create
      token = current_account.tokens.new(bearer: product, **token_params)
      authorize! token,
        with: Products::TokenPolicy

      if token.save
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

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = Current.resource = FindByAliasService.call(
        scoped_products,
        id: params[:product_id],
        aliases: :code,
      )
    end
  end
end
