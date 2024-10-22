# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Raw::ReleaseArtifactsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_artifact, only: %i[show]

    def show
      authorize! artifact

      redirect_to vanity_v1_account_release_artifact_url(artifact.account, artifact, filename: artifact.filename),
        allow_other_host: true,
        status: :see_other
    end

    private

    attr_reader :artifact

    def set_artifact
      scoped_artifacts = authorized_scope(current_account.release_artifacts)
        .for_product(params[:product_id])
        .for_package(params[:package_id])
        .for_release(params[:release_id])

      Current.resource = @artifact = FindByAliasService.call(
        scoped_artifacts.order_by_version,
        id: params[:id],
        aliases: :filename,
        reorder: false,
      )
    end
  end
end
