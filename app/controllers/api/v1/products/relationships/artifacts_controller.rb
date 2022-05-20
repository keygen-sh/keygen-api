# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ArtifactsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    def index
      artifacts = apply_pagination(policy_scope(apply_scopes(product.release_artifacts)).preload(:platform, :arch, :filetype))
      authorize artifacts

      render jsonapi: artifacts
    end

    def show
      artifact = FindByAliasService.call(scope: product.release_artifacts, identifier: params[:id], aliases: :key)
      authorize artifact

      download = DownloadArtifactService.call(
        account: current_account,
        ttl: artifact_query[:ttl],
        artifact:,
      )

      BroadcastEventService.call(
        event: 'release.downloaded',
        account: current_account,
        resource: artifact,
      )

      render jsonapi: artifact, status: :see_other, location: download.redirect_url
    rescue DownloadArtifactService::InvalidTTLError => e
      render_bad_request detail: e.message, source: { parameter: :ttl }
    rescue DownloadArtifactService::InvalidArtifactError => e
      render_not_found detail: e.message
    rescue DownloadArtifactService::YankedReleaseError => e
      render_unprocessable_entity detail: e.message
    end

    private

    attr_reader :product

    def set_product
      @product = current_account.products.find params[:product_id]
      authorize product, :show?

      Current.resource = product
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
