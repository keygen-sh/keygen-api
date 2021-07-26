# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ArtifactsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    def index
      artifacts = policy_scope apply_scopes(product.release_artifacts)
      authorize artifacts

      render jsonapi: artifacts
    end

    def show
      artifact = FindByAliasService.call(scope: product.release_artifacts, identifier: params[:id], aliases: :key)
      authorize artifact

      download = ReleaseDownloadService.call(
        account: current_account,
        release: artifact.release,
        ttl: artifact_query[:ttl],
      )

      BroadcastEventService.call(
        event: 'release.downloaded',
        account: current_account,
        resource: download.artifact,
      )

      render jsonapi: download.artifact, status: :see_other, location: download.redirect_url
    rescue ReleaseDownloadService::InvalidTTLError => e
      render_bad_request detail: e.message, source: { parameter: :ttl }
    rescue ReleaseDownloadService::InvalidArtifactError => e
      render_not_found detail: e.message
    rescue ReleaseDownloadService::YankedReleaseError => e
      render_unprocessable_entity detail: e.message
    end

    private

    attr_reader :product

    def set_product
      @product = current_account.products.find params[:product_id]
      authorize product, :show?

      Keygen::Store::Request.store[:current_resource] = product
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
