# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_release

    authorize :release

    def show
      product = release.product
      authorize! product,
        with: Releases::ProductPolicy

      render jsonapi: product
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(current_account.releases)

      @release = FindByAliasService.call(scoped_releases, id: params[:release_id], aliases: %i[version tag])

      Current.resource = release
    end
  end
end
