# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Rubygems::GemsController < Api::V1::BaseController
    use_primary only: %i[show]

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_artifact

    def show
      authorize! artifact

      # FIXME(ezekg) typically, we'd redirect to the vanity url but rubygems isn't forwarding auth to redirects
      download = artifact.download!(
        ttl: 10.minutes,
      )

      BroadcastEventService.call(
        event: 'artifact.downloaded',
        account: current_account,
        resource: artifact,
      )

      redirect_to download.url, status: :see_other, allow_other_host: true
    end

    private

    attr_reader :artifact

    def set_artifact
      scoped_artifacts = authorized_scope(current_account.release_artifacts.gems)

      @artifact = Current.resource = FindByAliasService.call(
        scoped_artifacts,
        id: "#{params[:gem]}.gem",
        aliases: :filename,
      )
    end
  end
end
