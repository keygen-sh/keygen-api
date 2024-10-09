# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ReleaseChannelsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      channels = apply_pagination(authorized_scope(apply_scopes(product.release_channels)))
      authorize! channels,
        with: Products::ReleaseChannelPolicy

      render jsonapi: channels
    end

    def show
      channel = product.release_channels.find(params[:id])
      authorize! channel,
        with: Products::ReleaseChannelPolicy

      render jsonapi: channel
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      Current.resource = @product = FindByAliasService.call(
        scoped_products,
        id: params[:product_id],
        aliases: :code,
      )
    end
  end
end
