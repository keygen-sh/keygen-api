# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_license

    authorize :license

    def show
      product = license.product
      authorize! product,
        with: Licenses::ProductPolicy

      render jsonapi: product
    end

    private

    attr_reader :license

    def set_license
      scoped_licenses = authorized_scope(current_account.licenses)

      @license = FindByAliasService.call(scoped_licenses, id: params[:license_id], aliases: :key)

      Current.resource = license
    end
  end
end
