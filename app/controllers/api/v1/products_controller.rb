# frozen_string_literal: true

module Api::V1
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product, only: [:show, :update, :destroy]

    def index
      products = apply_pagination(authorized_scope(apply_scopes(current_account.products)).preload(:role))
      authorize! products

      render jsonapi: products
    end

    def show
      authorize! product

      render jsonapi: product
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[product products] }
        param :attributes, type: :hash do
          param :name, type: :string
          param :distribution_strategy, type: :string, optional: true
          param :url, type: :string, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
          param :platforms, type: :array, allow_nil: true, optional: true do
            items type: :string
          end

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_account.ent? && current_bearer&.has_role?(:admin, :developer, :environment) } do
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
      product = current_account.products.new(product_params)
      authorize! product

      if product.save
        BroadcastEventService.call(
          event: "product.created",
          account: current_account,
          resource: product
        )

        render jsonapi: product, status: :created, location: v1_account_product_url(product.account, product)
      else
        render_unprocessable_resource product
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[product products] }
        param :id, type: :uuid, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, optional: true
          param :distribution_strategy, type: :string, allow_nil: true, optional: true
          param :url, type: :string, allow_nil: true, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
          param :platforms, type: :array, allow_nil: true, optional: true do
            items type: :string
          end

          Keygen.ee do |license|
            next unless
              license.entitled?(:permissions)

            param :permissions, type: :array, optional: true, if: -> { current_account.ent? && current_bearer&.has_role?(:admin, :developer, :environment) } do
              items type: :string
            end
          end
        end
      end
    }
    def update
      authorize! product

      if product.update(product_params)
        BroadcastEventService.call(
          event: "product.updated",
          account: current_account,
          resource: product
        )

        render jsonapi: product
      else
        render_unprocessable_resource product
      end
    end

    def destroy
      authorize! product

      BroadcastEventService.call(
        event: "product.deleted",
        account: current_account,
        resource: product
      )

      product.destroy_async
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = scoped_products.find(params[:id])

      Current.resource = product
    end
  end
end
