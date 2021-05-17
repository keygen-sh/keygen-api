# frozen_string_literal: true

module Api::V1::Releases::Actions
  class UpdatesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token

    def download_update
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
      authorize updater.current

      if updater.next.present?
        authorize updater.next

        # TODO(ezekg) Add location header pointing to S3

        BroadcastEventService.call(
          event: 'release.downloaded-update',
          account: current_account,
          resource: updater.next,
          meta: {
            version: updater.current.version,
          }
        )

        render jsonapi: updater.next, status: :see_other, location: ''
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
      on :download_update do
        query :product, type: :string
        query :platform, type: :string
        query :version, type: :string
        query :constraint, type: :string, optional: true
        query :channel, type: :string, optional: true
      end
    end
  end
end
