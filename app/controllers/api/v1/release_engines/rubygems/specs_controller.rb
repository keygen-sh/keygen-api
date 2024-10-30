# frozen_string_literal: true

require 'rubygems/version'

module Api::V1::ReleaseEngines
  class Rubygems::SpecsController < Api::V1::BaseController
    include Compression

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_packages, except: %i[quick_gemspec]
    before_action :set_artifact, only: %i[quick_gemspec]

    def quick_gemspec
      authorize! artifact,
        to: :show?

      # rubygems expects marshalled and zlib compressed gemspec
      gemspec = artifact.manifest.as_gemspec
      dumped  = Marshal.dump(gemspec)
      zipped  = deflate(dumped)

      return unless
        stale?(zipped, cache_control: { max_age: 1.day, private: true })

      send_data zipped, filename: "#{params[:gem]}.gemspec.rz"
    end

    def specs
      authorize! packages,
        to: :index?

      artifacts = authorized_scope(current_account.release_artifacts.unyanked.stable.for_packages(packages.ids).gems).preload(:manifest, release: %i[product entitlements constraints])
      authorize! artifacts,
        to: :index?

      # rubygems expects a marshalled and gzipped array of arrays
      specs  = to_specs(artifacts)
      dumped = Marshal.dump(specs)
      zipped = gzip(dumped)

      return unless
        stale?(zipped, cache_control: { max_age: 1.day, private: true })

      send_data zipped
    end

    def latest_specs
      authorize! packages,
        to: :index?

      # use "distinct on" to select latest accessible version per-package and -platform
      scoped_artifacts = authorized_scope(current_account.release_artifacts.unyanked.stable.for_packages(packages.ids).gems)
      latest_artifacts = ReleaseArtifact.from(
                                          scoped_artifacts.order_by_version.select('releases.release_package_id, release_artifacts.*'),
                                          scoped_artifacts.table_name,
                                        )
                                        .reorder(nil) # remove default order for "distinct on"
                                        .distinct_on(
                                          :release_package_id,
                                          :release_platform_id,
                                        )

      artifacts = latest_artifacts.where_assoc_exists(:manifest) # must exist
                                  .preload(:manifest,
                                    release: %i[product entitlements constraints],
                                  )
      authorize! artifacts,
        to: :index?

      specs  = to_specs(artifacts)
      dumped = Marshal.dump(specs)
      zipped = gzip(dumped)

      return unless
        stale?(zipped, cache_control: { max_age: 1.day, private: true })

      send_data zipped
    end

    def prerelease_specs
      authorize! packages,
        to: :index?

      artifacts = authorized_scope(current_account.release_artifacts.unyanked.prerelease.for_packages(packages.ids).gems)
                    .where_assoc_exists(:manifest) # must exist
                    .preload(:manifest,
                      release: %i[product entitlements constraints],
                    )
      authorize! artifacts,
        to: :index?

      specs  = to_specs(artifacts)
      dumped = Marshal.dump(specs)
      zipped = gzip(dumped)

      return unless
        stale?(zipped, cache_control: { max_age: 1.day, private: true })

      send_data zipped
    end

    private

    attr_reader :packages,
                :artifact

    def to_specs(artifacts)
      return [] unless artifacts.present?

      specs = artifacts.map do |artifact|
        gemspec = artifact.manifest.as_gemspec

        [gemspec.name, Gem::Version.new(gemspec.version), gemspec.platform.to_s]
      end

      specs.sort_by(&:third)  # platform
           .sort_by(&:second) # version
           .sort_by(&:first)  # name
    end

    def set_packages
      @packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems))
                    .preload(:product)
                    .where_assoc_exists(
                      # we want to ignore packages without any eligible gem specs
                      %i[releases artifacts manifest],
                    )
    end

    def set_artifact
      scoped_artifacts = authorized_scope(current_account.release_artifacts.gems)
                           .where_assoc_exists(:manifest) # must exist
                           .includes(
                             :manifest,
                           )

      Current.resource = @artifact = FindByAliasService.call(
        scoped_artifacts,
        id: "#{params[:gem]}.gem",
        aliases: :filename,
      )
    end
  end
end
