# frozen_string_literal: true

module Api::V1::Releases::Relationships::V1x0
  class ReleaseArtifactsController < Api::V1::BaseController
    use_primary only: %i[show]

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[show]
    before_action :authenticate_with_token, only: %i[show]
    before_action :set_release

    typed_query {
      param :ttl, type: :integer, coerce: true, allow_nil: true, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :environment) }
    }
    def show
      authorize! release,
        with: Releases::V1x0::DownloadPolicy,
        to: :download?

      download = ::V1x0::ReleaseDownloadService.call(
        account: current_account,
        release: release,
        ttl: release_artifact_query[:ttl],
      )

      BroadcastEventService.call(
        event: 'release.downloaded',
        account: current_account,
        resource: download.artifact,
      )

      render jsonapi: download.artifact, status: :see_other, location: download.redirect_url
    rescue ::V1x0::ReleaseDownloadService::TooManyArtifactsError => e
      render_unprocessable_entity detail: e.message
    rescue ::V1x0::ReleaseDownloadService::InvalidTTLError => e
      render_bad_request detail: e.message, source: { parameter: :ttl }
    rescue ::V1x0::ReleaseDownloadService::InvalidArtifactError => e
      render_not_found detail: e.message
    rescue ::V1x0::ReleaseDownloadService::YankedReleaseError => e
      render_unprocessable_entity detail: e.message
    end

    def create
      authorize! release,
        with: Releases::V1x0::UploadPolicy,
        to: :upload?

      upload = ::V1x0::ReleaseUploadService.call(
        account: current_account,
        release: release,
      )

      BroadcastEventService.call(
        event: 'release.uploaded',
        account: current_account,
        resource: release
      )

      render jsonapi: upload.artifact, status: :temporary_redirect, location: upload.redirect_url
    rescue ::V1x0::ReleaseUploadService::InvalidArtifactError,
           ::V1x0::ReleaseUploadService::YankedReleaseError => e
      render_unprocessable_entity detail: e.message
    end

    def destroy
      authorize! release,
        with: Releases::V1x0::YankPolicy,
        to: :yank?

      ::V1x0::ReleaseYankService.call(account: current_account, release: release)

      BroadcastEventService.call(
        event: 'release.yanked',
        account: current_account,
        resource: release
      )
    rescue ::V1x0::ReleaseYankService::InvalidArtifactError,
           ::V1x0::ReleaseYankService::YankedReleaseError => e
      render_unprocessable_entity detail: e.message
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(current_account.releases)

      @release = scoped_releases.find(params[:release_id])

      Current.resource = release
    end
  end
end
