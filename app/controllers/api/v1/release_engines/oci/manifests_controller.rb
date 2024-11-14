# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Oci::ManifestsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package

      manifest = package.manifests.find_by_reference!(params[:reference], content_type: request.accepts.collect(&:to_s))
      authorize! manifest.artifact

      # for etag support
      return unless
        stale?(manifest, cache_control: { max_age: 1.day, private: true })

      # docker is very particular about content types
      response.content_type = manifest.content_type

      render body: manifest.content
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
