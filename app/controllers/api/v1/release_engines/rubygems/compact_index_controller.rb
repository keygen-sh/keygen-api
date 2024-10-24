# frozen_string_literal: true

require 'compact_index'

module Api::V1::ReleaseEngines
  class Rubygems::CompactIndexController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_packages, only: %i[versions names]
    before_action :set_package, only: %i[info]

    def ping
      skip_verify_authorized!

      head :ok
    end

    def versions
      authorize! packages,
        to: :index?

      artifacts = authorized_scope(current_account.release_artifacts.unyanked.for_packages(packages.ids)).preload(:specification, :package, release: %i[product entitlements constraints])
      authorize! artifacts,
        to: :index?

      gems = artifacts.group_by(&:package).reduce([]) do |gemset, (package, artifacts)|
        versions = artifacts.map do |artifact|
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

        gemset << CompactIndex::Gem.new(package.key, versions.sort)
      end

      render plain: CompactIndex.versions(
        CompactIndex::Ext::VersionsFile.new(gems.sort),
      )
    end

    def info
      authorize! package,
        to: :show?

      artifacts = authorized_scope(package.artifacts.unyanked).preload(:specification, release: %i[product entitlements constraints])
      authorize! artifacts,
        to: :index?

      versions = artifacts.map do |artifact|
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

      render plain: CompactIndex.info(versions.sort)
    end

    def names
      authorize! packages,
        to: :index?

      names = packages.reorder(key: :asc)
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
      @packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems))
                    .preload(:product)
                    .joins(
                      # we want to ignore packages without any eligible gem specs
                      releases: { artifacts: :specification },
                    )
    end

    def set_package
      scoped_packages = authorized_scope(current_account.release_packages.rubygems)
                          .joins(
                            releases: { artifacts: :specification }, # must exist
                          )

      Current.resource = @package = FindByAliasService.call(
        scoped_packages,
        id: params[:gem],
        aliases: :key,
      )
    end
  end
end
