# frozen_string_literal: true

class ReleaseUpdateService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidProductError < StandardError; end
  class InvalidPlatformError < StandardError; end
  class InvalidFiletypeError < StandardError; end
  class InvalidVersionError < StandardError; end
  class InvalidConstraintError < StandardError; end
  class InvalidChannelError < StandardError; end
  class UpdateResult < OpenStruct; end

  def initialize(account:, product:, platform:, filetype:, version:, constraint: nil, channel: 'stable')
    raise InvalidAccountError.new('account must be present') unless
      account.present?

    raise InvalidProductError.new('product must be present') unless
      product.present?

    raise InvalidPlatformError.new('platform must be present') unless
      platform.present?

    raise InvalidFiletypeError.new('filetype must be present') unless
      filetype.present?

    raise InvalidVersionError.new('current version must be present') unless
      version.present?

    raise InvalidChannelError.new('channel must be present') unless
      channel.present?

    @account    = account
    @product    = product
    @platform   = platform
    @filetype   = filetype
    @version    = version
    @constraint = constraint
    @channel    = channel
  end

  def call
    current_version = current_semver&.to_s
    current_release =
      if current_version.present?
        available_releases.find_by(version: current_version)
      else
        nil
      end

    next_version = next_semver&.to_s
    next_release =
      if next_version.present?
        available_updates.find_by(version: next_version)
      else
        nil
      end

    UpdateResult.new(
      current_version: current_version,
      current_release: current_release,
      next_version: next_version,
      next_release: next_release,
    )
  end

  private

  attr_reader :account,
              :product,
              :platform,
              :filetype,
              :version,
              :constraint,
              :channel

  def available_releases
    @available_releases ||= account.releases.for_product(product)
                                            .for_platform(platform)
                                            .for_filetype(filetype)
  end

  def available_updates
    @available_updates ||= available_releases.for_channel(channel)
                                             .unyanked
  end

  def update_versions
    @update_versions ||= available_updates.limit(10_000)
                                          .pluck(:version)
  end

  def current_semver
    @current_semver ||= Semverse::Version.new(version)
  rescue Semverse::InvalidVersionFormat
    raise InvalidVersionError.new 'current version must be a valid semver: x.y.z or x.y.z-beta.1'
  end

  def next_semver
    semvers = update_versions.map { |v| Semverse::Version.new(v) }
                             .reject { |v| v <= current_semver }

    if constraint.present?
      prerelease =
        if channel.instance_of?(ReleaseChannel)
          channel.key
        else
          channel
        end

      op, major, minor, patch, prerelease_tag, build_tag =
        Semverse::Constraint.split(constraint)

      raise InvalidConstraintError.new 'version constraint cannot contain prerelease tag (use channel)' if
        prerelease_tag.present?

      raise InvalidConstraintError.new 'version constraint cannot contain build tag' if
        build_tag.present?

      rule  = "~> #{major}"
      rule += ".#{minor}" if minor.present?
      rule += ".#{patch}" if patch.present?
      rule += "-#{prerelease}" if
        prerelease.present? && prerelease != 'stable'

      semver = Semverse::Constraint.satisfy_best(
        [Semverse::Constraint.new(rule)],
        semvers
      )

      return semver
    end

    semvers.sort.last
  rescue Semverse::InvalidConstraintFormat
    raise InvalidConstraintError.new 'version constraint must be valid: x, x.y, x.y.z'
  rescue Semverse::NoSolutionError => e
    Keygen.logger.warn "[release_update_service] No solution found: current=#{current_semver} constraint=#{constraint} rule=(#{rule}) versions=(#{semvers.join(', ')})"

    nil
  end
end
