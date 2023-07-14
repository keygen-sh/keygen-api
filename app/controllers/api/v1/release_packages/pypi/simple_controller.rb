# frozen_string_literal: true

module Api::V1::ReleasePackages
  class Pypi::SimpleController < Api::V1::BaseController
    include Rendering

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_product, only: %i[show]

    def index
      products = authorized_scope(apply_scopes(current_account.products.pypi)).limit(1_000)
      authorize! products,
        with: ReleasePackages::Pypi::SimplePolicy

      render 'api/v1/release_packages/pypi/simple/index',
        layout: 'layouts/plain',
        locals: {
          account: current_account,
          products:,
        }
    end

    def show
      artifacts = authorized_scope(apply_scopes(product.release_artifacts.pypi)).limit(1_000)
      authorize! artifacts,
        with: ReleasePackages::Pypi::SimplePolicy

      render 'api/v1/release_packages/pypi/simple/show',
        layout: 'layouts/plain',
        locals: {
          account: current_account,
          product:,
          artifacts:,
        }
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = FindByAliasService.call(
        scoped_products.pypi,
        id: params[:package],
        aliases: :code,
      )
    rescue Keygen::Error::NotFoundError
      # Redirect to PyPI when not found to play nicely with PyPI not supporting a per-package index
      # TODO(ezekg) Make this configurable?
      url = URI.parse("https://pypi.org/simple")
      pkg = CGI.escape(params[:package])

      url.path += "/#{pkg}"

      redirect_to url.to_s, status: :temporary_redirect,
                            allow_other_host: true
    end
  end
end
