# frozen_string_literal: true

module Api::V1::Products::Relationships
  class AppcastsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    def show
      releases = policy_scope apply_scopes(product.releases.preload(:artifact, :channel, :platform))
      authorize releases

      headers['Content-Disposition'] = 'attachment; filename="appcast.xml"'
      headers['Content-Type']        = 'application/xml'

      render xml: GenerateAppcastService.call(account: current_account, product: product, releases: releases)
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
