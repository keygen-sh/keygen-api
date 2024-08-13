module Api::V1::Releases::Actions
  class PublishingsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_release

    def publish
      authorize! release

      release.publish!

      BroadcastEventService.call(
        event: 'release.published',
        account: current_account,
        resource: release,
      )

      render jsonapi: release
    end

    def yank
      authorize! release

      release.yank!

      BroadcastEventService.call(
        event: 'release.yanked',
        account: current_account,
        resource: release,
      )

      render jsonapi: release
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(current_account.releases)

      @release = FindByAliasService.call(
        scoped_releases,
        id: params[:id],
        aliases: %i[version tag],
      )

      Current.resource = release
    end
  end
end
