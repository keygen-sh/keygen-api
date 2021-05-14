# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ReleasesController < Api::V1::BaseController
    has_scope(:platform, only: :index) { |_, s, v| s.for_platform(v) }
    has_scope(:channel, default: 'stable', only: :index) { |_, s, v|
      s.for_channel(v)
    }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    def index
      releases = apply_scopes(product.releases)
      authorize releases

      render jsonapi: releases
    end

    def show
      release = product.releases.find params[:id]
      authorize release

      render jsonapi: release
    end

    def create
    end

    def update
    end

    def destroy
    end

    private

    attr_reader :product

    def set_product
      @product = current_account.products.find params[:product_id]

      Keygen::Store::Request.store[:current_resource] = product
    end
  end
end
