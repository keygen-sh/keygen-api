# frozen_string_literal: true

require 'rubygems/specification'
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

      gems = packages.preload(releases: { artifacts: %i[specification platform] }).map do |package|
        versions = package.releases.flat_map do |release|
          next unless release.published?

          release.artifacts.map do |artifact|
            next unless artifact.uploaded?
            next if artifact.specification.nil?

            gemspec = Gem::Specification.from_yaml(
              artifact.specification.content,
            )

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

        CompactIndex::Gem.new(package.key, versions.compact.sort)
      end

      render plain: CompactIndex.versions(
        CompactIndex::Ext::VersionsFile.new(gems.sort),
      )
    end

    def info
      authorize! package,
        to: :show?

      versions = package.releases.preload(artifacts: %i[specification platform]).flat_map do |release|
        next unless release.published?

        release.artifacts.map do |artifact|
          next unless artifact.uploaded?
          next if artifact.specification.nil?

          gemspec = Gem::Specification.from_yaml(
            artifact.specification.content,
          )

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

      render plain: CompactIndex.info(versions.compact.sort)
    end

    def names
      authorize! packages,
        to: :index?

      names = packages.pluck(
        :key,
      )

      render plain: CompactIndex.names(names.sort)
    end

    private

    attr_reader :packages,
                :package

    def set_packages
      @packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems)).preload(:product)
    end

    def set_package
      Current.resource = @package = FindByAliasService.call(
        authorized_scope(current_account.release_packages.rubygems),
        id: params[:package],
        aliases: :key,
      )
    end
  end
end
