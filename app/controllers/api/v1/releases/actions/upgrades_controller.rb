# frozen_string_literal: true

module Api::V1::Releases::Actions
  class UpgradesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release, only: %i[check_for_upgrade_by_id]

    def check_for_upgrade_by_query
      kwargs = upgrade_query.to_h.symbolize_keys.slice(
        :product,
        :platform,
        :filetype,
        :version,
        :constraint,
        :channel,
      )

      check_for_upgrade(**kwargs)
    rescue ReleaseUpgradeService::InvalidProductError => e
      render_bad_request detail: e.message, code: :UPGRADE_PRODUCT_INVALID, source: { parameter: :product }
    rescue ReleaseUpgradeService::InvalidPlatformError => e
      render_bad_request detail: e.message, code: :UPGRADE_PLATFORM_INVALID, source: { parameter: :platform }
    rescue ReleaseUpgradeService::InvalidFiletypeError => e
      render_bad_request detail: e.message, code: :UPGRADE_FILETYPE_INVALID, source: { parameter: :filetype }
    rescue ReleaseUpgradeService::InvalidVersionError => e
      render_bad_request detail: e.message, code: :UPGRADE_VERSION_INVALID, source: { parameter: :version }
    rescue ReleaseUpgradeService::InvalidConstraintError => e
      render_bad_request detail: e.message, code: :UPGRADE_CONSTRAINT_INVALID, source: { parameter: :constraint }
    rescue ReleaseUpgradeService::InvalidChannelError => e
      render_bad_request detail: e.message, code: :UPGRADE_CHANNEL_INVALID, source: { parameter: :channel }
    rescue Pundit::NotAuthorizedError
      render status: :no_content
    end

    def check_for_upgrade_by_id
      kwargs = upgrade_query.to_h.symbolize_keys
        .slice(:constraint, :channel)
        .merge(
          product: release.product_id,
          platform: release.platform_id,
          filetype: release.filetype_id,
          version: release.version,
        )

      check_for_upgrade(**kwargs)
    rescue ReleaseUpgradeService::InvalidConstraintError => e
      render_bad_request detail: e.message, code: :UPGRADE_CONSTRAINT_INVALID, source: { parameter: :constraint }
    rescue ReleaseUpgradeService::InvalidChannelError => e
      render_bad_request detail: e.message, code: :UPGRADE_CHANNEL_INVALID, source: { parameter: :channel }
    rescue ReleaseUpgradeService::InvalidProductError,
           ReleaseUpgradeService::InvalidPlatformError,
           ReleaseUpgradeService::InvalidFiletypeError,
           ReleaseUpgradeService::InvalidVersionError
      render_unprocessable_entity
    rescue Pundit::NotAuthorizedError
      render status: :no_content
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = policy_scope(current_account.releases)

      @release = scoped_releases.find(params[:id])

      Keygen::Store::Request.store[:current_resource] = release
    end

    def check_for_upgrade(**kwargs)
      upgrade = ReleaseUpgradeService.call(
        account: current_account,
        **kwargs,
      )

      Keygen.logger.debug "[releases.check_for_upgrade] Upgrade: account=#{current_account.id} current_release=#{upgrade.current_release&.id} current_version=#{upgrade.current_version} next_release=#{upgrade.next_release&.id} next_version=#{upgrade.next_version}"

      if upgrade.next_release.present?
        authorize upgrade.next_release, :download?

        download = ReleaseDownloadService.call(account: current_account, release: upgrade.next_release, ttl: 10.minutes, upgrade: true)
        meta     = {
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
        if upgrade.current_release.present?
          authorize upgrade.current_release, :download?
        else
          # When current and next release are nil, we can skip authorization,
          # since there's nothing to assert authorization for.
          skip_authorization
        end

        render status: :no_content
      end
    rescue ReleaseDownloadService::InvalidArtifactError => e
      Keygen.logger.warn "[releases.check_for_upgrade] No artifact found: account=#{current_account.id} current_release=#{upgrade.current_release&.id} current_version=#{upgrade.current_version} next_release=#{upgrade.next_release&.id} next_version=#{upgrade.next_version} reason=#{e.class.name}"

      # NOTE(ezekg) This scenario will likely only happen when we're in-between creating a new release
      #             and uploading it. In the interim, we'll act as if the release doesn't exist yet.
      render status: :no_content
    end

    typed_query do
      on :check_for_upgrade_by_query do
        query :product, type: :string
        query :platform, type: :string
        query :filetype, type: :string
        query :version, type: :string
        query :constraint, type: :string, optional: true
        query :channel, type: :string, optional: true
      end

      on :check_for_upgrade_by_id do
        query :constraint, type: :string, optional: true
        query :channel, type: :string, optional: true
      end
    end
  end
end
