# frozen_string_literal: true

module Api::V1
  class ArtifactsController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_artifact, only: [:show]

    def index
      # We're applying scopes after the policy scope because our policy scope
      # may include a UNION, and scopes/preloading need to be applied after
      # the UNION query has been performed. E.g. for LIMIT.
      artifacts = apply_pagination(apply_scopes(policy_scope(current_account.release_artifacts)))
      authorize artifacts

      render jsonapi: artifacts
    end

    def show
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

    attr_reader :artifact

    def set_artifact
      scoped_artifacts = policy_scope(current_account.release_artifacts)

      @artifact = FindByAliasService.call(scope: scoped_artifacts, identifier: params[:id], aliases: :key)

      Current.resource = artifact
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
