# frozen_string_literal: true

module Api::V1::ReleaseEngines
  class Npm::PackageMetadataController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_package

    def show
      authorize! package

      artifacts = authorized_scope(package.artifacts.tarballs).order_by_version
        .where_assoc_exists(:manifest) # must exist
        .preload(:manifest,
          release: %i[product entitlements constraints],
        )
      authorize! artifacts,
        to: :index?

      # FIXME(ezekg) https://github.com/brianhempel/active_record_union/issues/35
      last_modified = artifacts.collect(&:updated_at).max
      latest        = artifacts.first
      metadata      = artifacts.reduce(
        name: package.key,
        time: { created: package.created_at, modified: last_modified },
        'dist-tags': { latest: latest.version },
        versions: {},
      ) do |metadata, artifact|
        package_json = artifact.manifest.as_package_json

        # TODO(ezekg) implement signatures?
        checksums = case [artifact.checksum_encoding, artifact.checksum_algorithm]
                    in [:base64, :sha256 | :sha384 | :sha512 => algorithm]
                      # see: https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
                      { integrity: "#{algorithm}-#{artifact.checksum}" }
                    in [:hex, :sha1]
                      { shasum: artifact.checksum }
                    else
                      {}
                    end

        metadata[:time][artifact.version]     = artifact.created_at.iso8601(3)
        metadata[:'dist-tags'][artifact.tag]  = artifact.version if artifact.tag?
        metadata[:versions][artifact.version] = package_json.merge(
          dist: {
            tarball: vanity_v1_account_release_artifact_url(current_account, artifact, filename: artifact.filename, host: request.host),
            **checksums,
          },
        )

        metadata
      end

      # for etag support
      return unless
        stale?(metadata, last_modified:, cache_control: { max_age: 10.minutes, private: true })

      render json: metadata
    end

    private

    attr_reader :package

    def set_package
      scoped_packages = authorized_scope(current_account.release_packages.npm)
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
