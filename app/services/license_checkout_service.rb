# frozen_string_literal: true

class LicenseCheckoutService < AbstractCheckoutService
  class InvalidAccountError < StandardError; end
  class InvalidLicenseError < StandardError; end
  class InvalidIncludeError < StandardError; end

  ALLOWED_INCLUDES = %w[
    entitlements
    product
    policy
    group
    user
  ]

  def initialize(account:, license:, encrypt: false, ttl: 1.month, include: [])
    raise InvalidAccountError, 'account must be present' unless
      account.present?

    raise InvalidLicenseError, 'license must be present' unless
      license.present?

    raise InvalidIncludeError, 'invalid includes' if
      (include - ALLOWED_INCLUDES).any?

    @account = account
    @license = license

    private_key =
      case license.scheme
      when 'RSA_2048_PKCS1_PSS_SIGN_V2',
           'RSA_2048_PKCS1_SIGN_V2',
           'RSA_2048_PKCS1_PSS_SIGN',
           'RSA_2048_PKCS1_SIGN',
           'RSA_2048_PKCS1_ENCRYPT',
           'RSA_2048_JWT_RS256'
        account.private_key
      else
        account.ed25519_private_key
      end

    algorithm =
      case license.scheme
      when 'RSA_2048_PKCS1_PSS_SIGN_V2',
           'RSA_2048_PKCS1_PSS_SIGN'
        'rsa-pss-sha256'
      when 'RSA_2048_PKCS1_SIGN_V2',
           'RSA_2048_PKCS1_SIGN',
           'RSA_2048_PKCS1_ENCRYPT',
           'RSA_2048_JWT_RS256'
        'rsa-sha256'
      else
        'ed25519'
      end

    super(private_key: private_key, algorithm: algorithm, encrypt: encrypt, ttl: ttl, include: include)
  end

  def call
    iat = Time.current
    exp = if ttl?
            iat + ActiveSupport::Duration.build(ttl)
          else
            nil
          end

    meta = { iat: iat, exp: exp, ttl: ttl }
    incl = includes & ALLOWED_INCLUDES
    data = renderer.render(license, meta: meta, include: incl)
                   .to_json

    enc = if encrypted?
            encrypt(data, secret: license.key)
          else
            encode(data, strict: true)
          end
    sig = sign(enc, prefix: 'license')

    alg = if encrypted?
            "#{ENCRYPT_ALGORITHM}+#{algorithm}"
          else
            "#{ENCODE_ALGORITHM}+#{algorithm}"
          end

    doc = { enc: enc, sig: sig, alg: alg }
    enc = encode(doc.to_json)

    <<~TXT
      -----BEGIN LICENSE FILE-----
      #{enc}
      -----END LICENSE FILE-----
    TXT
  end

  private

  attr_reader :account,
              :license
end
