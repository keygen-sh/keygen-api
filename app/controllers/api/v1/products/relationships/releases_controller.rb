# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ReleasesController < Api::V1::BaseController
    has_scope(:yanked, type: :boolean, allow_blank: true) { |c, s, v| !!v ? s.yanked : s.unyanked }
    has_scope(:channel, default: 'stable') { |c, s, v| s.for_channel(v) }
    has_scope(:platform) { |c, s, v| s.for_platform(v) }
    has_scope(:filetype) { |c, s, v| s.for_filetype(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    def index
      releases = apply_scopes(product.releases.preload(:platform, :filetype, :channel))
      authorize releases

      render jsonapi: releases
    end

    def show
      release = product.releases.find params[:id]
      authorize release

      render jsonapi: release
    end

    private

    attr_reader :product

    def set_product
      @product = current_account.products.find params[:product_id]

      Keygen::Store::Request.store[:current_resource] = product
    end
  end
end
