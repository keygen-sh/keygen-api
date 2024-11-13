# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::BlobsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package

      descriptor = package.descriptors.find_by!(content_digest: params[:digest])
      authorize! descriptor.artifact

      redirect_to vanity_v1_account_release_artifact_url(current_account, descriptor.artifact, filename: descriptor.content_path, host: request.host),
        status: :see_other
    end

    private

    attr_reader :package

    def set_package
      scoped_packages = authorized_scope(current_account.release_packages.oci)
                          .where_assoc_exists(
                            %i[releases artifacts manifest], # must exist
                          )

      @package = Current.resource = FindByAliasService.call(
        scoped_packages,
        id: params[:package],
        aliases: :key,
      )
    end
  end
end
