# frozen_string_literal: true

module Api::V1::Releases::Relationships
  class ReleaseEnginesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_release

    authorize :release

    def show
      engine = release.engine
      authorize! engine,
        with: Releases::ReleaseEnginePolicy

      render jsonapi: engine
    end

    private

    attr_reader :release

    def set_release
      scoped_releases = authorized_scope(current_account.releases)

      @release = FindByAliasService.call(scoped_releases, id: params[:release_id], aliases: %i[version tag])

      Current.resource = release
    end
  end
end
