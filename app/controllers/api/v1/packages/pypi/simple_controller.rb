
module Api::V1::Packages
  class Pypi::SimpleController < Api::V1::BaseController
    include AbstractController::Rendering

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_content_type
    before_action :set_product

    authorize :product

    def index
      @artifacts = authorized_scope(apply_scopes(product.release_artifacts)).preload(release: %i[product entitlements constraints]).limit(1_000)
      authorize! @artifacts,
        with: Products::ReleaseArtifactPolicy

      render 'api/v1/packages/pypi/simple/index'
    end

    private

    attr_reader :product

    def set_content_type = response.headers['Content-Type'] = 'text/html'

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = FindByAliasService.call(
        scope: scoped_products,
        identifier: params[:id],
        aliases: :slug,
      )

      # TODO(ezekg) Add a distribution_engine attribute to product?
    rescue Keygen::Error::NotFoundError
      redirect_to "https://pypi.org/simple/#{params[:id]}", allow_other_host: true, status: :see_other
    end
  end
end
