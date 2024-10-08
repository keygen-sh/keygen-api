# frozen_string_literal: true

require 'open-uri'
require 'rubygems/package'
require 'compact_index'

module Api::V1::ReleaseEngines
  class Rubygems::SpecsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token
    before_action :set_release_package, only: %i[show info quick_gemspec]
    before_action :set_artifact, only: %i[show quick_gemspec]

    def index
    end

    def prerelease_specs
      release_packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems)).preload(releases: :channel)

      authorize! release_packages, to: :index?

      specs = release_packages.flat_map do |release_package|
        release_package.releases.map do |release|
          next if release.stable?

          [release_package.key, Gem::Version.new(release.version), "ruby"]
        end.compact
      end

      serve_gziped_specs(specs)
    end

    def specs
      release_packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems)).preload(:releases)

      authorize! release_packages, to: :index?

      specs = release_packages.flat_map do |release_package|
        release_package.releases.map do |release|
          next unless release.stable?

          [reletease_package.key, Gem::Version.new(release.version), "ruby"]
        end.compact
      end

      serve_gziped_specs(specs)
    end

    def latest_specs
      release_packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems)).preload(:ordered_releases)

      authorize! release_packages, to: :index?

      specs = release_packages.map do |release_package|
        release = release_package.ordered_releases.first
        next if !release || !release.stable?

        [release_package.key, Gem::Version.new(release.version), "ruby"]
      end.compact

      serve_gziped_specs(specs)
    end

    def quick_gemspec
      gemfile = open(artifact.download!.url)
      spec_file = Gem::Package.new(gemfile).spec

      serve_gziped_specs(spec_file)
    end

    def info
      versions = release_package.releases.flat_map do |release|
        release.artifacts.map do |artifact|
          gemfile = open(artifact.download!.url)
          spec_file = Gem::Package.new(gemfile).spec

          dependencies = spec_file.dependencies.map do |dependency|
            CompactIndex::Dependency.new(
              dependency.name.to_s, dependency.requirement.to_s
            )
          end

          CompactIndex::GemVersion.new(
            spec_file.version.to_s, spec_file.platform.to_s, nil, nil, dependencies
          )
        end
      end

      render plain: CompactIndex.info(versions)
    end

    def versions
      release_packages = authorized_scope(apply_scopes(current_account.release_packages.rubygems)).preload(:ordered_releases)

      authorize! release_packages, to: :index?

      packages = release_packages.map do |release_package|
        versions = release_package.ordered_releases.reverse_each.map do |release|
          CompactIndex::GemVersion.new(release.version, 'ruby')
        end

        CompactIndex::Gem.new(release_package.key, versions)
      end

      versions_file = CompactIndex::VersionsFile.new(Tempfile.new)
      versions_file.create(packages)

      render plain: CompactIndex.versions(versions_file)
    end

    def show
      gemfile = open(artifact.download!.url)

      send_data gemfile
    end

    private

    attr_reader :artifact, :release_package

    def set_release_package
      package_key, _ = parse_package_name(params[:package])

      @release_package = FindByAliasService.call(
        authorized_scope(apply_scopes(current_account.release_packages.rubygems)).preload(:releases),
        id: package_key,
        aliases: :key,
      )

      authorize! @release_package
    end

    def set_artifact
      _, version = parse_package_name(params[:package])

      release = release_package.releases.find { |release| release.version == version }
      render_not_found unless release

      @artifact = release.artifacts.find { |artifact| artifact.filename.include?(params[:package]) }
      render_not_found unless @artifact

      authorize! @artifact
    end

    def parse_package_name(package)
      package_key, _, version = package.partition(/-(?=\d)/)

      [package_key, version]
    end

    def serve_gziped_specs(specs)
      buffer = StringIO.new

      Zlib::GzipWriter.wrap(buffer) do |gz|
        gz.write(Marshal.dump(specs))
      end

      send_data(buffer.string)
    end
  end
end
