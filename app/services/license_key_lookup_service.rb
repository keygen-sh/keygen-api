# frozen_string_literal: true

class LicenseKeyLookupService < BaseService
  ENCRYPTED_KEY_RE = /\A(?<license_id>.{#{UUID_LENGTH}})-(?<bits>.+)/.freeze

  def initialize(account:, key:, environment: nil, legacy_encrypted: false)
    @account          = account
    @key              = key
    @environment      = environment
    @legacy_encrypted = legacy_encrypted
  end

  def call
    # FIXME(ezekg) So wrong... but it's my own damn vault! Hashing != encryption.
    if legacy_encrypted
      matches = ENCRYPTED_KEY_RE.match(key)
      return unless
        matches.present?

      license = licenses.find_by(id: matches[:license_id])

      if license&.compare_hashed_token(:key, key, version: 'v1')
        license
      else
        nil
      end
    else
      licenses.find_by(key:)
    end
  end

  private

  attr_reader :environment,
              :account,
              :key

  # FIXME(ezekg) Remove this after usage drops off (LUL)
  attr_reader :legacy_encrypted

  def licenses = account.licenses.for_environment(environment, strict: true)
end
