# frozen_string_literal: true

module Api::V1::ReleasePackages
  class Pypi::SimpleController < Api::V1::BaseController
    include Rendering

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token

    def index
      products = authorized_scope(apply_scopes(current_account.products.pypi)).limit(1_000)
      packages = ReleasePackage.for(products)
      authorize! packages,
        with: ReleasePackagePolicy # can't be inferred when empty

      render 'api/v1/release_packages/pypi/simple/index',
        layout: 'layouts/plain',
        locals: {
          account: current_account,
          packages:,
        }
    end

    def show
      product = FindByAliasService.call(
        authorized_scope(current_account.products.pypi),
        id: params[:id],
        aliases: :code,
      )

      artifacts = authorized_scope(apply_scopes(product.release_artifacts.pypi)).limit(1_000)
      package   = ReleasePackage.new(product, artifacts:)
      authorize! package

      render 'api/v1/release_packages/pypi/simple/show',
        layout: 'layouts/plain',
        locals: {
          account: current_account,
          package:,
        }
    rescue Keygen::Error::NotFoundError
      skip_verify_authorized!

      # Redirect to PyPI when not found to play nicely with PyPI not supporting a per-package index
      # TODO(ezekg) Make this configurable?
      url = URI.parse("https://pypi.org/simple")
      pkg = CGI.escape(params[:id])

      url.path += "/#{pkg}"

      redirect_to url.to_s, status: :temporary_redirect,
                            allow_other_host: true
    end
  end
end
