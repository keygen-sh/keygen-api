# frozen_string_literal: true

class LicenseCheckoutService < AbstractCheckoutService
  class InvalidIncludeError < StandardError; end
  class InvalidLicenseError < StandardError; end

  ALLOWED_INCLUDES = %w[
    entitlements
    environment
    product
    policy
    group
    user
  ].freeze

  def initialize(license:, environment: nil, include: [], **kwargs)
    raise InvalidLicenseError, 'license must be present' unless
      license.present?

    raise InvalidIncludeError, 'invalid includes' if
      (include - ALLOWED_INCLUDES).any?

    @license     = license
    @environment = environment

    super(scheme: license.scheme, include:, **kwargs)
  end

  def call
    issued_at  = Time.current
    expires_at = if ttl?
                   issued_at + ActiveSupport::Duration.build(ttl)
                 else
                   nil
                 end

    meta = { issued: issued_at, expiry: expires_at, ttl: ttl }
    incl = includes & ALLOWED_INCLUDES
    data = renderer.render(license, meta: meta, include: incl)
                   .to_json

    enc = if encrypted?
            encrypt(data, secret: license.key)
          else
            encode(data, strict: true)
          end
    sig = sign(enc, key: private_key, algorithm: algorithm, prefix: 'license')
    alg = if encrypted?
            "#{ENCRYPT_ALGORITHM}+#{algorithm}"
          else
            "#{ENCODE_ALGORITHM}+#{algorithm}"
          end

    doc  = { enc: enc, sig: sig, alg: alg }
    enc  = encode(doc.to_json)
    cert = <<~TXT
      -----BEGIN LICENSE FILE-----
      #{enc}
      -----END LICENSE FILE-----
    TXT

    LicenseFile.new(
      environment_id: environment&.id,
      account_id: account.id,
      license_id: license.id,
      certificate: cert,
      issued_at: issued_at,
      expires_at: expires_at,
      ttl: ttl,
      includes: incl,
    )
  end

  private

  attr_reader :environment,
              :license
end
