# frozen_string_literal: true

require 'compact_index'

module Api::V1::ReleaseEngines
  class Npm::PackageMetadataController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package,
        to: :show?

      artifacts = authorized_scope(package.artifacts.npm_package_tgz).order_by_version
        .where_assoc_exists(:manifest) # must exist
        .preload(:manifest,
          release: %i[product entitlements constraints],
        )
      authorize! artifacts,
        to: :index?

      last_modified = artifacts.maximum(:"#{artifacts.table_name}.updated_at")
      latest        = artifacts.first
      metadata      = artifacts.reduce(
        name: package.key,
        time: { created: package.created_at, modified: last_modified },
        'dist-tags': { latest: latest.version },
        versions: {},
      ) do |metadata, artifact|
        package_json = artifact.manifest.as_package_json

        metadata[:time][artifact.version]     = artifact.created_at.iso8601(3)
        metadata[:'dist-tags'][artifact.tag]  = artifact.version if artifact.tag?
        metadata[:versions][artifact.version] = package_json.merge(
          dist: {
            tarball: vanity_v1_account_release_artifact_url(current_account, artifact, filename: artifact.filename, host: request.host),
          },
        )

        metadata
      end

      # for etag support
      return unless
        stale?(metadata, last_modified:, cache_control: { max_age: 1.day, private: true })

      render json: metadata
    end

    private

    attr_reader :package

    def set_package
      scoped_packages = authorized_scope(current_account.release_packages.npm)
                          .where_assoc_exists(
                            %i[releases artifacts manifest], # must exist
                          )

      Current.resource = @package = FindByAliasService.call(
        scoped_packages,
        id: params[:package],
        aliases: :key,
      )
    end
  end
end
