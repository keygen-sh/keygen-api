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

      artifacts = authorized_scope(current_account.release_artifacts.unyanked.for_packages(packages.ids).gems)
                    .where_assoc_exists(:manifest) # must exist
                    .preload(:manifest, :package,
                      release: %i[product entitlements constraints],
                    )
      authorize! artifacts,
        to: :index?

      gems = artifacts.group_by(&:package).reduce([]) do |arr, (package, artifacts)|
        versions = to_versions(artifacts)

        arr << CompactIndex::Gem.new(package.key, versions.sort)
      end

      versions = CompactIndex.versions(
        CompactIndex::Ext::VersionsFile.new(gems.sort),
      )

      # for etag support
      return unless
        stale?(versions, cache_control: { max_age: 1.day, private: true })

      render plain: versions
    end

    def info
      authorize! package,
        to: :show?

      artifacts = authorized_scope(package.artifacts.unyanked.gems)
                    .where_assoc_exists(:manifest) # must exist
                    .preload(:manifest,
                      release: %i[product entitlements constraints],
                    )
      authorize! artifacts,
        to: :index?

      versions = to_versions(artifacts)
      info     = CompactIndex.info(
        versions.sort,
      )

      return unless
        stale?(info, cache_control: { max_age: 1.day, private: true })

      render plain: info
    end

    def names
      authorize! packages,
        to: :index?

      names = CompactIndex.names(
        packages.reorder(key: :asc)
                .distinct
                .pluck(
                  :key,
                ),
      )

      return unless
        stale?(names, cache_control: { max_age: 1.day, private: true })

      render plain: names
    end

    private

    attr_reader :packages,
                :package

    def to_versions(artifacts)
      return [] unless artifacts.present?

      artifacts.map do |artifact|
        gemspec      = artifact.manifest.as_gemspec
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

    def set_packages
      @packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems))
                    .preload(:product)
                    .where_assoc_exists(
                      # we want to ignore packages without any eligible gem specs
                      %i[releases artifacts manifest],
                    )
    end

    def set_package
      scoped_packages = authorized_scope(current_account.release_packages.rubygems)
                          .where_assoc_exists(
                            %i[releases artifacts manifest], # must exist
                          )

      Current.resource = @package = FindByAliasService.call(
        scoped_packages,
        id: params[:gem],
        aliases: :key,
      )
    end
  end
end
