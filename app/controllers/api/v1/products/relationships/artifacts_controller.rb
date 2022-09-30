# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ArtifactsController < Api::V1::BaseController
    has_scope(:channel) { |c, s, v| s.for_channel(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }
    has_scope(:filetype) { |c, s, v| s.for_filetype(v) }
    has_scope(:platform) { |c, s, v| s.for_platform(v) }
    has_scope(:arch) { |c, s, v| s.for_arch(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product, only: %i[index show]
    before_action :set_artifact, only: %i[show]

    authorize :product

    def index
      artifacts = apply_pagination(authorized_scope(apply_scopes(product.release_artifacts)).preload(:platform, :arch, :filetype))
      authorize! artifacts,
        with: Products::ReleaseArtifactPolicy

      render jsonapi: artifacts
    end

    def show
      authorize! artifact,
        with: Products::ReleaseArtifactPolicy

      # Respond early if the artifact has not been uploaded or if the
      # client prefers no-download
      return render jsonapi: artifact if
        !artifact.downloadable? || prefers?('no-download')

      download = artifact.download!(ttl: artifact_query[:ttl])

      BroadcastEventService.call(
        event: %w[artifact.downloaded release.downloaded],
        account: current_account,
        resource: artifact,
      )

      # Respond without a redirect if that's what the client prefers
      render jsonapi: artifact, location: download.url if
        prefers?('no-redirect')

      render jsonapi: artifact, status: :see_other, location: download.url
    end

    private

    attr_reader :product,
                :artifact

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = scoped_products.find(params[:product_id])

      Current.resource = product
    end

    def set_artifact
      scoped_artifacts = authorized_scope(apply_scopes(product.release_artifacts))

      @artifact = FindByAliasService.call(
        scope: scoped_artifacts.order_by_version,
        identifier: params[:id],
        aliases: :filename,
        reorder: false,
      )
    end

    typed_query do
      on :show do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          query :ttl, type: :integer, coerce: true, optional: true
        end
      end
    end
  end
end
