# frozen_string_literal: true

module Api::V1::Releases::Actions
  class UpdatesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release, only: %i[check_for_update_by_id]

    def check_for_update_by_query
      skip_authorization # Handled downstream

      kwargs = update_query.to_h.symbolize_keys.slice(
        :product,
        :platform,
        :filetype,
        :version,
        :constraint,
        :channel,
      )

      check_for_update(**kwargs)
    rescue ReleaseUpdateService::InvalidProductError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_PRODUCT, source: { parameter: :product }
    rescue ReleaseUpdateService::InvalidPlatformError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_PLATFORM, source: { parameter: :platform }
    rescue ReleaseUpdateService::InvalidFiletypeError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_FILETYPE, source: { parameter: :filetype }
    rescue ReleaseUpdateService::InvalidVersionError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_VERSION, source: { parameter: :version }
    rescue ReleaseUpdateService::InvalidConstraintError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_CONSTRAINT, source: { parameter: :constraint }
    rescue ReleaseUpdateService::InvalidChannelError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_CHANNEL, source: { parameter: :channel }
    rescue Pundit::NotAuthorizedError
      render status: :no_content
    end

    def check_for_update_by_id
      skip_authorization # Handled downstream

      kwargs = update_query.to_h.symbolize_keys
        .slice(:constraint, :channel)
        .merge(
          product: release.product_id,
          platform: release.platform_id,
          filetype: release.filetype_id,
          version: release.version,
        )

      check_for_update(**kwargs)
    rescue ReleaseUpdateService::InvalidConstraintError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_CONSTRAINT, source: { parameter: :constraint }
    rescue ReleaseUpdateService::InvalidChannelError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_CHANNEL, source: { parameter: :channel }
    rescue ReleaseUpdateService::InvalidProductError,
           ReleaseUpdateService::InvalidPlatformError,
           ReleaseUpdateService::InvalidFiletypeError,
           ReleaseUpdateService::InvalidVersionError
      render_unprocessable_entity
    rescue Pundit::NotAuthorizedError
      render status: :no_content
    end

    private

    attr_reader :release

    def set_release
      @release = current_account.releases.find(params[:id])

      Keygen::Store::Request.store[:current_resource] = release
    end

    def check_for_update(**kwargs)
      updater = ReleaseUpdateService.call(
        account: current_account,
        **kwargs,
      )
      authorize updater.current_release, :download? if
        updater.current_release.present?

      if updater.next_release.present?
        authorize updater.next_release, :download?

        # Assert object exists before redirecting to S3
        s3  = Aws::S3::Client.new
        obj = s3.head_object(bucket: 'keygen-dist', key: updater.next_release.s3_object_key)

        # TODO(ezekg) Check if IP address is from EU and use: bucket=keygen-dist-eu region=eu-west-2
        # NOTE(ezekg) Check obj.replication_status for EU
        signer = Aws::S3::Presigner.new
        ttl    = 60.seconds.to_i
        url    = signer.presigned_url(:get_object, bucket: 'keygen-dist', key: updater.next_release.s3_object_key, expires_in: ttl)
        link   = updater.next_release.update_links.create!(account: current_account, url: url, ttl: ttl)
        meta   = {
          current: updater.current_version,
          next: updater.next_version,
        }

        BroadcastEventService.call(
          event: 'release.update-downloaded',
          account: current_account,
          resource: updater.next_release,
          meta: meta,
        )

        render jsonapi: link, meta: meta, status: :see_other, location: link.url
      else
        render status: :no_content
      end
    rescue Aws::S3::Errors::NotFound
      Keygen.logger.warn "[releases.updates] No blob found: account=#{current_account.id} current_release=#{updater.current_release&.id} current_version=#{updater.current_version} next_release=#{updater.next_release&.id} next_version=#{updater.next_version}"

      # NOTE(ezekg) This scenario will likely only happen when we're in-between creating a new release
      #             and uploading it. In the interim, we'll act as if the release doesn't exist yet.
      render status: :no_content
    end

    typed_query do
      on :check_for_update_by_query do
        query :product, type: :string
        query :platform, type: :string
        query :filetype, type: :string
        query :version, type: :string
        query :constraint, type: :string, optional: true
        query :channel, type: :string, optional: true
      end

      on :check_for_update_by_id do
        query :constraint, type: :string, optional: true
        query :channel, type: :string, optional: true
      end
    end
  end
end
