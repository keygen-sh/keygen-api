# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::ManifestsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_artifact

    def show
      authorize! artifact,
        to: :show?

      manifest = artifact.manifest

      # for etag support
      return unless
        stale?(manifest, cache_control: { max_age: 1.day, private: true })

      render body: manifest.content
    end

    private

    attr_reader :artifact

    def set_artifact
      Current.resource = @artifact = authorized_scope(current_account.release_artifacts.tarballs)
                                       .for_package(params[:namespace])
                                       .for_release(params[:reference])
                                       .order_by_version
                                       .first!
    end
  end
end
