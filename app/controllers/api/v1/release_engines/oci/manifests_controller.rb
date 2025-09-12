# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::ManifestsController < Api::V1::BaseController
    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package,
        with: ReleaseEngines::Oci::ReleasePackagePolicy

      # NOIE(ezekg) because docker expects WWW-Authenticate challenges, we can't scope like
      #             we usually do, so we'll apply some bare-minimum scoping and then do
      #             the rest of the asserts in the controller and policy.
      manifest = authorized_scope(package.manifests, with: ReleaseEngines::Oci::ReleaseManifestPolicy)
                   .find_by_reference!(params[:reference],
                     accepts: request.accepts.collect(&:to_s),
                     prefers: %w[
                       application/vnd.oci.image.index.v1+json
                       application/vnd.docker.distribution.manifest.list.v2+json
                       application/vnd.oci.image.manifest.v1+json
                       application/vnd.docker.distribution.manifest.v2+json
                     ],
                   )
      authorize! manifest,
        with: ReleaseEngines::Oci::ReleaseManifestPolicy

      # for etag support
      return unless
        stale?(manifest, cache_control: { max_age: 10.minutes, private: true })

      # oci spec is very particular about content length and media types
      response.headers['Content-Length'] = manifest.content_length
      response.headers['Content-Type']   = manifest.content_type

      if request.head?
        response.headers['Docker-Content-Digest'] = manifest.content_digest # oras likes this

        # see: https://github.com/opencontainers/distribution-spec/blob/main/spec.md#checking-if-content-exists-in-the-registry
        head :ok
      else
        render body: manifest.content
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
                            :manifests, # must exist
                          )

      @package = Current.resource = FindByAliasService.call(
        scoped_packages,
        id: params[:package],
        aliases: :key,
      )
    end
  end
end
