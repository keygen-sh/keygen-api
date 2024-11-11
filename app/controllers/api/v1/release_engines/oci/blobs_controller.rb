# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::BlobsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_artifact

    def show
      authorize! artifact

      redirect_to vanity_v1_account_release_artifact_url(artifact.account, artifact, filename: artifact.filename, host: request.host),
        status: :see_other
    end

    private

    attr_reader :artifact

    def set_artifact
      scoped_artifacts = authorized_scope(current_account.release_artifacts.blobs)
                           .for_package(params[:namespace])

      # see: https://github.com/opencontainers/image-spec/blob/main/descriptor.md#digests
      algorithm, encoded = params[:digest].split(':', 2)

      Current.resource = @artifact = scoped_artifacts.find_by!(
        filename: "blobs/#{algorithm}/#{encoded}",
      )
    end
  end
end
