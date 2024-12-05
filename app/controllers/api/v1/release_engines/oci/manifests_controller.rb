# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::ManifestsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package

      manifest = authorized_scope(package.manifests).find_by_reference!(
        params[:reference],
        content_type: request.accepts.collect(&:to_s),
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
    end

    private

    attr_reader :package

    def set_package
      scoped_packages = authorized_scope(current_account.release_packages.oci)
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
