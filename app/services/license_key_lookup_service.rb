class LicenseKeyLookupService < BaseService
  ENCRYPTED_KEY_REGEX = /\A(.{#{UUID_LENGTH}})/ # Form: {uuid}-xxxx-xxxx-xxxx

  def initialize(account:, key:, legacy_encrypted:)
    @account          = account
    @key              = key
    @legacy_encrypted = legacy_encrypted
  end

  def execute
    licenses = account.licenses

    # FIXME(ezekg) So wrong but it's my own dang vault: hashing != encryption
    if legacy_encrypted
      matches = ENCRYPTED_KEY_REGEX.match key
      license = licenses.find_by id: matches[1]

      if license&.compare_hashed_token(:key, key, version: "v1")
        license
      else
        nil
      end
    else
      licenses.find_by key: key
    end
  end

  private

  attr_reader :account, :key, :legacy_encrypted
end
