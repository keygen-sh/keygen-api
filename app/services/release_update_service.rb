# frozen_string_literal: true

class ReleaseUpdateService < BaseService
  def initialize(account:, product:, platform:, current_version:, constrain_version: nil, channel: 'stable')
    @account           = account
    @product           = product
    @platform          = platform
    @current_version   = current_version
    @constrain_version = constrain_version
    @channel           = channel
  end

  def call
    version = next_version
    return nil if
      version.nil?

    available_releases.find_by(version: version.to_s)
  end

  private

  attr_reader :account,
              :product,
              :platform,
              :current_version,
              :constrain_version,
              :channel

  def available_releases
    @available_releases ||= account.releases.for_product(product)
                                            .for_platform(platform)
                                            .for_channel(channel)
  end

  def available_versions
    @available_versions ||= available_releases.limit(10_000).pluck(:version)
  end

  def next_version
    current_semver = Semverse::Version.new(current_version)
    semvers        = available_versions.map { |v| Semverse::Version.new(v) }
                                       .reject { |v| v <= current_semver }

    if constrain_version.present?
      semver     = Semverse::Version.new(constrain_version)
      constraint =
        if channel.present?
          "~> #{semver.major}.#{semver.minor}-#{channel}"
        else
          "~> #{semver.major}.#{semver.minor}"
        end

      return Semverse::Constraint.satisfy_best(
        [Semverse::Constraint.new(constraint)],
        semvers
      )
    end

    semvers.sort.last
  rescue Semverse::NoSolutionError
    nil
  end
end
