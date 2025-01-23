# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::ManifestsController < Api::V1::BaseController
    before_action :require_ee!
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package

      manifest = package.manifests.find_by_reference!(params[:reference],
        accepts: request.accepts.collect(&:to_s),
        prefers: %w[
          application/vnd.oci.image.index.v1+json
          application/vnd.docker.distribution.manifest.list.v2+json
          application/vnd.oci.image.manifest.v1+json
          application/vnd.docker.distribution.manifest.v2+json
        ],
      )
      authorize! manifest

      # for etag support
      return unless
        stale?(manifest, cache_control: { max_age: 1.day, private: true })

      # oci spec is very particular about content/media types
      response.content_type = manifest.content_type

      if request.head?
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
      # NOTE(ezekg) see above comment i.r.t. docker authentication on why we're
      #             skipping authorized_scope here and elsewhere
      scoped_packages = current_account.release_packages.oci.where_assoc_exists(
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
