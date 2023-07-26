# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ReleasesController < Api::V1::BaseController
    has_scope(:yanked, type: :boolean, allow_blank: true) { |c, s, v| !!v ? s.yanked : s.unyanked }
    has_scope(:package, allow_blank: true) { |c, s, v| s.for_package(v.presence) }
    has_scope(:engine, allow_blank: true) { |c, s, v| s.for_engine(v.presence) }
    has_scope(:channel) { |c, s, v| s.for_channel(v) }

    # FIXME(ezekg) Eventually remove these once we can confirm they're
    #              no longer being used
    has_scope(:filetype, if: -> c { c.current_api_version == '1.0' }) { |c, s, v| s.for_filetype(v) }
    has_scope(:platform, if: -> c { c.current_api_version == '1.0' }) { |c, s, v| s.for_platform(v) }
    has_scope(:arch,     if: -> c { c.current_api_version == '1.0' }) { |c, s, v| s.for_arch(v) }
    has_scope(:version,  if: -> c { c.current_api_version == '1.0' }) { |c, s, v| s.with_version(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      releases = apply_pagination(authorized_scope(apply_scopes(product.releases)).preload(:channel))
      authorize! releases,
        with: Products::ReleasePolicy

      render jsonapi: releases
    end

    def show
      release = FindByAliasService.call(product.releases, id: params[:id], aliases: %i[version tag])
      authorize! release,
        with: Products::ReleasePolicy

      render jsonapi: release
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = scoped_products.find(params[:product_id])

      Current.resource = product
    end
  end
end
