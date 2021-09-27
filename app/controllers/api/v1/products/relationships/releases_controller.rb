# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ReleasesController < Api::V1::BaseController
    has_scope(:yanked, type: :boolean, allow_blank: true) { |c, s, v| !!v ? s.yanked : s.unyanked }
    has_scope(:platform) { |c, s, v| s.for_platform(v) }
    has_scope(:filetype) { |c, s, v| s.for_filetype(v) }
    has_scope(:channel) { |c, s, v| s.for_channel(v) }
    has_scope(:version) { |c, s, v| s.with_version(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    def index
      releases = policy_scope apply_scopes(product.releases.preload(:artifact, :platform, :filetype, :channel))
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
      authorize product, :show?

      Keygen::Store::Request.store[:current_resource] = product
    end
  end
end
