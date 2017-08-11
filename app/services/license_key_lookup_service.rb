class LicenseKeyLookupService < BaseService
  ENCRYPTED_KEY_REGEX = /\A(.{#{UUID_LENGTH}})/ # Form: {uuid}-xxxx-xxxx-xxxx

  def initialize(account:, encrypted:, key:, scope: nil)
    @account   = account
    @encrypted = encrypted
    @key       = key
    @scope     = scope
  end

  def execute
    licenses = account.licenses
    if scope.present? && !scope.empty?
      scope.each { |k, v| licenses = licenses.send(k, v) }
    end

    if encrypted
      key =~ ENCRYPTED_KEY_REGEX # Run regex against key

      license = licenses.find_by id: $1

      if license&.compare_encrypted_token(:key, key)
        license
      else
        nil
      end
    else
      licenses.find_by key: key
    end
  end

  private

  attr_reader :account, :encrypted, :key, :scope
end
