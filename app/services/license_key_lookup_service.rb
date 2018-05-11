class LicenseKeyLookupService < BaseService
  ENCRYPTED_KEY_REGEX = /\A(.{#{UUID_LENGTH}})/ # Form: {uuid}-xxxx-xxxx-xxxx

  def initialize(account:, encrypted:, key:)
    @account   = account
    @encrypted = encrypted
    @key       = key
  end

  def execute
    licenses = account.licenses

    if encrypted
      key =~ ENCRYPTED_KEY_REGEX # Run regex against key

      license = licenses.find_by id: $1

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

  attr_reader :account, :encrypted, :key
end
