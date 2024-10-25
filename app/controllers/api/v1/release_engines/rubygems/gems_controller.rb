# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Rubygems::GemsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_artifact

    def show
      authorize! artifact

      # give just enough time for even slow connections to download the gem
      link = artifact.download!(
        ttl: 10.minutes,
      )

      BroadcastEventService.call(
        event: 'artifact.downloaded',
        account: current_account,
        resource: artifact,
      )

      # rubygems doesn't forward auth so we need to redirect directly to the backend
      redirect_to link.url, status: :see_other, allow_other_host: true
    end

    private

    attr_reader :artifact

    def set_artifact
      scoped_artifacts = authorized_scope(current_account.release_artifacts.gems)

      Current.resource = @artifact = FindByAliasService.call(
        scoped_artifacts,
        id: "#{params[:gem]}.gem",
        aliases: :filename,
      )
    end
  end
end
