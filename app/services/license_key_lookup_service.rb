class LicenseKeyLookupService < BaseService
  ENCRYPTED_KEY_REGEX = /\A(.{#{RESOURCE_UUID_LENGTH}})/ # Form: {uuid}-xxxx-xxxx-xxxx

  def initialize(account:, encrypted:, key:)
    @account   = account
    @encrypted = encrypted
    @key       = key
  end

  def execute
    if encrypted
      key =~ ENCRYPTED_KEY_REGEX # Run regex against key

      license = account.licenses.find_by id: $1

      if license&.compare_encrypted_token(:key, key)
        license
      else
        nil
      end
    else
      account.licenses.find_by key: key
    end
  end

  private

  attr_reader :account, :encrypted, :key
end
