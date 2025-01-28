# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::BlobsController < Api::V1::BaseController
    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package,
        with: ReleaseEngines::Oci::ReleasePackagePolicy

      descriptor = authorized_scope(package.descriptors, with: ReleaseEngines::Oci::ReleaseDescriptorPolicy)
                     .find_by!(
                       content_digest: params[:digest],
                     )
      authorize! descriptor,
        with: ReleaseEngines::Oci::ReleaseDescriptorPolicy

      if request.head?
        response.headers['Docker-Content-Digest'] = descriptor.content_digest # oras likes these
        response.headers['Content-Length']        = descriptor.content_length

        # see: https://github.com/opencontainers/distribution-spec/blob/main/spec.md#checking-if-content-exists-in-the-registry
        head :ok
      else
        redirect_to vanity_v1_account_release_artifact_url(current_account, descriptor.artifact, filename: descriptor.content_path, host: request.host),
          status: :see_other
      end
    rescue ActionPolicy::Unauthorized
      # FIXME(ezekg) docker expects a 401 Unauthorized response with an WWW-Authenticate
      #              challenge, so unfortunately, we can't return a 404 here like we
      #              usually do for unauthorized requests (so as not to leak data).
      if current_bearer.nil?
        render_unauthorized(code: 'UNAUTHORIZED')
      else
        render_forbidden(code: 'DENIED')
      end
    end

    private

    attr_reader :package

    def require_ee! = super(entitlements: %i[oci_engine])

    def set_package
      scoped_packages = authorized_scope(current_account.release_packages.oci, with: ReleaseEngines::Oci::ReleasePackagePolicy)
                          .where_assoc_exists(
                            :descriptors, # must exist
                          )

      @package = Current.resource = FindByAliasService.call(
        scoped_packages,
        id: params[:package],
        aliases: :key,
      )
    end
  end
end
