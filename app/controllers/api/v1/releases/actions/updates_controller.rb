# frozen_string_literal: true

module Api::V1::Releases::Actions
  class UpdatesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!

    def check_for_update
      kwargs = update_query.to_h.symbolize_keys.slice(
        :product,
        :platform,
        :version,
        :constraint,
        :channel
      )

      updater = ReleaseUpdateService.call(
        account: current_account,
        **kwargs
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
        link   = updater.next_release.download_links.create!(account: current_account, url: url, ttl: ttl)

        BroadcastEventService.call(
          event: 'release.update-downloaded',
          account: current_account,
          resource: updater.next_release,
          meta: {
            current_version: updater.current_version,
            next_version: updater.next_version,
          }
        )

        render jsonapi: updater.next_release, status: :see_other, location: link.url
      else
        render status: :no_content
      end
    rescue ReleaseUpdateService::InvalidAccountError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_ACCOUNT, source: { parameter: :account }
    rescue ReleaseUpdateService::InvalidProductError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_PRODUCT, source: { parameter: :product }
    rescue ReleaseUpdateService::InvalidPlatformError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_PLATFORM, source: { parameter: :platform }
    rescue ReleaseUpdateService::InvalidVersionError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_VERSION, source: { parameter: :version }
    rescue ReleaseUpdateService::InvalidConstraintError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_CONSTRAINT, source: { parameter: :constraint }
    rescue ReleaseUpdateService::InvalidChannelError => e
      render_bad_request detail: e.message, code: :INVALID_UPDATE_CHANNEL, source: { parameter: :channel }
    rescue Aws::S3::Errors::NotFound
      Keygen.logger.warn "[releases.updates] No blob found: account=#{current_account.id} current_release=#{updater.current_release&.id} current_version=#{updater.current_version} next_release=#{updater.next_release&.id} next_version=#{updater.next_version}"

      render status: :no_content
    end

    private

    typed_query do
      on :check_for_update do
        query :product, type: :string
        query :platform, type: :string
        query :version, type: :string
        query :constraint, type: :string, optional: true
        query :channel, type: :string, optional: true
      end
    end
  end
end
