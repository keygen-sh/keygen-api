# frozen_string_literal: true

module Api::V1::Releases::Actions::V1x0
  class UpgradesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate
    before_action :set_release, only: %i[check_for_upgrade_by_id]

    skip_verify_authorized only: %i[
      check_for_upgrade_by_query
      check_for_upgrade_by_id
    ]

    typed_query {
      param :product, type: :string
      param :platform, type: :string
      param :filetype, type: :string
      param :version, type: :string
      param :constraint, type: :string, optional: true
      param :channel, type: :string, optional: true
    }
    def check_for_upgrade_by_query
      kwargs = upgrade_query.slice(
        :product,
        :platform,
        :filetype,
        :version,
        :constraint,
        :channel,
      )

      check_for_upgrade(**kwargs)
    rescue ::V1x0::ReleaseUpgradeService::InvalidProductError => e
      render_bad_request detail: e.message, code: :UPGRADE_PRODUCT_INVALID, source: { parameter: :product }
    rescue ::V1x0::ReleaseUpgradeService::InvalidPlatformError => e
      render_bad_request detail: e.message, code: :UPGRADE_PLATFORM_INVALID, source: { parameter: :platform }
    rescue ::V1x0::ReleaseUpgradeService::InvalidFiletypeError => e
      render_bad_request detail: e.message, code: :UPGRADE_FILETYPE_INVALID, source: { parameter: :filetype }
    rescue ::V1x0::ReleaseUpgradeService::InvalidVersionError => e
      render_bad_request detail: e.message, code: :UPGRADE_VERSION_INVALID, source: { parameter: :version }
    rescue ::V1x0::ReleaseUpgradeService::InvalidConstraintError => e
      render_bad_request detail: e.message, code: :UPGRADE_CONSTRAINT_INVALID, source: { parameter: :constraint }
    rescue ::V1x0::ReleaseUpgradeService::InvalidChannelError => e
      render_bad_request detail: e.message, code: :UPGRADE_CHANNEL_INVALID, source: { parameter: :channel }
    rescue ActionPolicy::Unauthorized => e
      Keygen.logger.warn { "[releases.check_for_upgrade_by_query] policy=#{e.policy} rule=#{e.rule} message=#{e.message} reasons=#{e.result.reasons&.reasons}" }

      render status: :no_content
    end

    typed_query {
      param :constraint, type: :string, optional: true
      param :channel, type: :string, optional: true
    }
    def check_for_upgrade_by_id
      kwargs = upgrade_query.slice(:constraint, :channel)
                            .merge(
                              filetype: release.artifact.filetype_id,
                              platform: release.artifact.platform_id,
                              product: release.product_id,
                              version: release.version,
                            )

      check_for_upgrade(**kwargs)
    rescue ::V1x0::ReleaseUpgradeService::InvalidConstraintError => e
      render_bad_request detail: e.message, code: :UPGRADE_CONSTRAINT_INVALID, source: { parameter: :constraint }
    rescue ::V1x0::ReleaseUpgradeService::InvalidChannelError => e
      render_bad_request detail: e.message, code: :UPGRADE_CHANNEL_INVALID, source: { parameter: :channel }
    rescue ::V1x0::ReleaseUpgradeService::InvalidProductError,
           ::V1x0::ReleaseUpgradeService::InvalidPlatformError,
           ::V1x0::ReleaseUpgradeService::InvalidFiletypeError,
           ::V1x0::ReleaseUpgradeService::InvalidVersionError => e
      render_unprocessable_entity detail: e.message
    rescue ActionPolicy::Unauthorized => e
      Keygen.logger.warn { "[releases.check_for_upgrade_by_id] policy=#{e.policy} rule=#{e.rule} message=#{e.message} reasons=#{e.result.reasons&.reasons}" }

      render status: :no_content
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(current_account.releases)

      @release = scoped_releases.find(params[:id])

      Current.resource = release
    end

    def check_for_upgrade(platform:, filetype:, **kwargs)
      upgrade = ::V1x0::ReleaseUpgradeService.call(
        account: current_account,
        platform:,
        filetype:,
        **kwargs,
      )

      authorize! upgrade.current_release,
        with: Releases::V1x0::DownloadPolicy,
        to: :upgrade?

      Keygen.logger.debug "[releases.check_for_upgrade] Upgrade: account=#{current_account.id} current_release=#{upgrade.current_release&.id} current_version=#{upgrade.current_version} next_release=#{upgrade.next_release&.id} next_version=#{upgrade.next_version}"

      if upgrade.next_release.present?
        authorize! upgrade.next_release,
          with: Releases::V1x0::DownloadPolicy,
          to: :download?

        download = ::V1x0::ReleaseDownloadService.call(
          account: current_account,
          release: upgrade.next_release,
          upgrade: true,
          ttl: 1.hour,
          platform:,
          filetype:,
        )

        meta = {
          current: upgrade.current_version,
          next: upgrade.next_version,
        }

        BroadcastEventService.call(
          event: 'release.upgraded',
          account: current_account,
          resource: upgrade.next_release,
          meta: meta,
        )

        render jsonapi: download.artifact, meta: meta, status: :see_other, location: download.redirect_url
      else
        Keygen.logger.debug "[releases.check_for_upgrade] No upgrades found: account=#{current_account.id} current_release=#{upgrade.current_release&.id} current_version=#{upgrade.current_version} next_release=#{upgrade.next_release&.id} next_version=#{upgrade.next_version}"

        render status: :no_content
      end
    rescue ::V1x0::ReleaseDownloadService::TooManyArtifactsError => e
      render_unprocessable_entity detail: e.message
    rescue ::V1x0::ReleaseDownloadService::InvalidArtifactError => e
      Keygen.logger.warn "[releases.check_for_upgrade] No artifact found: account=#{current_account.id} current_release=#{upgrade.current_release&.id} current_version=#{upgrade.current_version} next_release=#{upgrade.next_release&.id} next_version=#{upgrade.next_version} reason=#{e.class.name}"

      # NOTE(ezekg) This scenario will likely only happen when we're in-between creating a new release
      #             and uploading it. In the interim, we'll act as if the release doesn't exist yet.
      render status: :no_content
    end
  end
end
