# frozen_string_literal: true

class LicenseCheckoutService < AbstractCheckoutService
  ALLOWED_INCLUDES = %w[
    entitlements
    product
    policy
    group
    user
  ]

  def initialize(license:, **kwargs)
    @license = license

    kwargs[:algorithm] ||=
      case license.scheme
      when 'RSA_2048_PKCS1_PSS_SIGN_V2',
           'RSA_2048_PKCS1_PSS_SIGN'
        'rsa-pss-sha256'
      when 'RSA_2048_PKCS1_SIGN_V2',
           'RSA_2048_PKCS1_SIGN'
        'rsa-sha256'
      when 'ED25519_SIGN',
           nil
        'ed25519'
      end

    super(**kwargs)
  end

  def call
    data = renderer.render(license, include: includes & ALLOWED_INCLUDES)
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

    iat = Time.current
    exp = if ttl?
            iat + ActiveSupport::Duration.build(ttl)
          else
            nil
          end

    doc = { enc: enc, sig: sig, alg: alg, iat: iat, exp: exp }
    enc = encode(doc.to_json)

    <<~TXT
      -----BEGIN LICENSE FILE-----
      #{enc}
      -----END LICENSE FILE-----
    TXT
  end

  private

  attr_reader :license
end
