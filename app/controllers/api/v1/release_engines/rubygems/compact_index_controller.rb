# frozen_string_literal: true

require 'compact_index'

module Api::V1::ReleaseEngines
  class Rubygems::CompactIndexController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_packages, only: %i[versions names]
    before_action :set_package, only: %i[info]

    def versions
      authorize! packages,
        to: :index?

      gems = packages.joins(published_releases: { uploaded_artifacts: :specification })
                     .eager_load(published_releases: { uploaded_artifacts: :specification }) # must exist
                     .preload(published_releases: { uploaded_artifacts: :platform })         # may exist
                     .distinct
                     .map do |package|
        versions = package.published_releases.flat_map do |release|
          release.uploaded_artifacts.map do |artifact|
            gemspec      = artifact.specification.as_gemspec
            dependencies = gemspec.dependencies.map do |dependency|
              CompactIndex::Dependency.new(dependency.name.to_s, dependency.requirement.to_s)
            end

            CompactIndex::GemVersion.new(
              gemspec.version.to_s,
              gemspec.platform.to_s,
              artifact.checksum,
              nil, # will be calculated via versions file
              dependencies,
              gemspec.required_ruby_version.to_s,
              gemspec.required_rubygems_version.to_s,
            )
          end
        end

        CompactIndex::Gem.new(package.key, versions.sort)
      end

      render plain: CompactIndex.versions(
        CompactIndex::Ext::VersionsFile.new(gems.sort),
      )
    end

    def info
      authorize! package,
        to: :show?

      versions = package.published_releases.joins(uploaded_artifacts: :specification)
                                           .eager_load(uploaded_artifacts: :specification) # must exist
                                           .preload(uploaded_artifacts: :platform)         # may exist
                                           .distinct
                                           .flat_map do |release|
        release.uploaded_artifacts.map do |artifact|
          gemspec      = artifact.specification.as_gemspec
          dependencies = gemspec.dependencies.map do |dependency|
            CompactIndex::Dependency.new(dependency.name.to_s, dependency.requirement.to_s)
          end

          CompactIndex::GemVersion.new(
            gemspec.version.to_s,
            gemspec.platform.to_s,
            artifact.checksum,
            nil, # unused
            dependencies,
            gemspec.required_ruby_version.to_s,
            gemspec.required_rubygems_version.to_s,
          )
        end
      end

      render plain: CompactIndex.info(versions.sort)
    end

    def names
      authorize! packages,
        to: :index?

      names = packages.joins(published_releases: { uploaded_artifacts: :specification })
                      .reorder(key: :asc)
                      .distinct
                      .pluck(
                        :key,
                      )

      render plain: CompactIndex.names(names)
    end

    private

    attr_reader :packages,
                :package

    def set_packages
      @packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems)).preload(:product)
    end

    def set_package
      scoped_packages = current_account.release_packages.rubygems
                                                        .joins(
                                                          # we want to ignore packages without any eligible versions
                                                          published_releases: { uploaded_artifacts: :specification },
                                                        )

      Current.resource = @package = FindByAliasService.call(
        authorized_scope(scoped_packages),
        id: params[:package],
        aliases: :key,
      )
    end
  end
end
