# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ArtifactsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!, except: %i[show]
    before_action :authenticate_with_token, only: %i[show]
    before_action :set_release

    def show
      authorize release, :download?

      download = ReleaseDownloadService.call(
        account: current_account,
        release: release,
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

    def create
      authorize release, :upload?

      upload = ReleaseUploadService.call(
        account: current_account,
        release: release,
      )

      BroadcastEventService.call(
        event: 'release.uploaded',
        account: current_account,
        resource: release
      )

      render jsonapi: upload.artifact, status: :temporary_redirect, location: upload.redirect_url
    rescue ReleaseUploadService::YankedReleaseError => e
      render_unprocessable_entity detail: e.message
    end

    def destroy
      authorize release, :yank?

      ReleaseYankService.call(account: current_account, release: release)

      BroadcastEventService.call(
        event: 'release.yanked',
        account: current_account,
        resource: release
      )
    rescue ReleaseYankService::YankedReleaseError => e
      render_unprocessable_entity detail: e.message
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = policy_scope(current_account.releases)

      @release = scoped_releases.find(params[:release_id])

      Keygen::Store::Request.store[:current_resource] = release
    end

    private

    typed_query do
      on :show do
        if current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
          query :ttl, type: :integer, coerce: true, optional: true
        end
      end
    end
  end
end
