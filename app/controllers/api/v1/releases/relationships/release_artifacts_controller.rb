# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ReleaseArtifactsController < Api::V1::BaseController
    has_scope(:status) { |c, s, v| s.with_status(v) }
    has_scope(:filetype) { |c, s, v| s.for_filetype(v) }
    has_scope(:platform) { |c, s, v| s.for_platform(v) }
    has_scope(:arch) { |c, s, v| s.for_arch(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[index show]
    before_action :authenticate_with_token, only: %i[index show]
    before_action :set_release, only: %i[index show]
    before_action :set_artifact, only: %i[show]

    authorize :release

    def index
      artifacts = apply_pagination(authorized_scope(apply_scopes(release.artifacts)).preload(:platform, :arch, :filetype))
      authorize! artifacts,
        with: Releases::ReleaseArtifactPolicy

      render jsonapi: artifacts
    end

    typed_query {
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :environment) }
    }
    def show
      authorize! artifact,
        with: Releases::ReleaseArtifactPolicy

      # Respond early if the artifact has not been uploaded (or is yanked) or
      # if the client prefers no download
      return render jsonapi: artifact if
        !artifact.downloadable? || prefers?('no-download')

      download_url = artifact.presigned_download_url(ttl: release_artifact_query[:ttl])

      BroadcastEventService.call(
        event: %w[artifact.downloaded release.downloaded],
        account: current_account,
        resource: artifact,
      )

      # Respond without a redirect if that's what the client prefers
      return render jsonapi: artifact, location: download_url if
        prefers?('no-redirect')

      render jsonapi: artifact, status: :see_other, location: download_url
    end

    private

    attr_reader :release,
                :artifact

    def set_release
      scoped_releases = authorized_scope(current_account.releases)

      @release = FindByAliasService.call(
        scoped_releases,
        id: params[:release_id],
        aliases: %i[version tag],
      )

      Current.resource = release
    end

    def set_artifact
      scoped_artifacts = authorized_scope(apply_scopes(release.artifacts))

      @artifact = FindByAliasService.call(
        scoped_artifacts.order_by_version,
        id: params[:id],
        aliases: :filename,
        reorder: false,
      )
    end
  end
end
