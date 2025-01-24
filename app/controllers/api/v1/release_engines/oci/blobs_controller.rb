# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::BlobsController < Api::V1::BaseController
    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package

      descriptor = package.descriptors.find_by!(
        content_digest: params[:digest],
      )
      authorize! descriptor

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
      # NOTE(ezekg) see above comment i.r.t. docker authentication on why we're
      #             skipping authorized_scope here and elsewhere
      scoped_packages = current_account.release_packages.oci.where_assoc_exists(
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
