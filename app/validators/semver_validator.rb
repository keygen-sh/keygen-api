# frozen_string_literal: true

class SemverValidator < ActiveModel::EachValidator
  SEMVER_CHANNELS = %w[rc beta alpha dev]

  def validate_each(record, attribute, value)
    semver = Semverse::Version.new(value)

    record.errors.add attribute, :channel_invalid, message: 'must be a valid channel' unless valid_channel?(semver)
  rescue Semverse::InvalidVersionFormat
    record.errors.add attribute, :invalid, message: 'must be a valid version'
  end

  private

  def valid_channel?(semver)
    return false if semver.nil?
    return true if !semver.pre_release?

    SEMVER_CHANNELS.any? { |channel|
      semver.pre_release.starts_with?(channel)
    }
  end
end
