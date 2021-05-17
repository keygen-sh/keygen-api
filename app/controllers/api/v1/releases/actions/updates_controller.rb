# frozen_string_literal: true

module Api::V1::Releases::Actions
  class UpdatesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token

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
      authorize updater.current_release if
        updater.current_release.present?

      if updater.next_release.present?
        authorize updater.next_release

        signer = Aws::S3::Presigner.new
        ttl = 60.seconds.to_i
        url = signer.presigned_url(:get_object, bucket: 'keygen-dist', key: updater.next_release.s3_object_key, expires_in: ttl)
        link = updater.next_release.download_links.create!(account: current_account, url: url, ttl: ttl)

        BroadcastEventService.call(
          event: 'release.update-downloaded',
          account: current_account,
          resource: updater.next_release,
          meta: {
            prev_version: updater.current_version,
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
