# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ChannelsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    def index
      channels = policy_scope apply_scopes(product.release_channels)
      authorize channels

      render jsonapi: channels
    end

    def show
      channel = product.release_channels.find params[:id]
      authorize channel

      render jsonapi: channel
    end

    private

    attr_reader :product

    def set_product
      @product = current_account.products.find params[:product_id]
      authorize product, :show?

      Keygen::Store::Request.store[:current_resource] = product
    end
  end
end
