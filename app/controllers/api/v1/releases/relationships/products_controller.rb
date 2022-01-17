# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    def show
      product = release.product
      authorize product

      render jsonapi: product
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = policy_scope(current_account.releases)

      @release = FindByAliasService.call(scope: scoped_releases, identifier: params[:release_id], aliases: :filename)

      Current.resource = release
    end
  end
end
