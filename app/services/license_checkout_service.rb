# frozen_string_literal: true

class LicenseCheckoutService < AbstractCheckoutService
  ALLOWED_INCLUDES = %w[
    entitlements
    product
    policy
    group
    user
  ]

  def initialize(...)
    super(...)
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
            "#{encryption_alg}+#{signing_alg}"
          else
            "#{encoding_alg}+#{signing_alg}"
          end

    iat = Time.current
    exp = if ttl?
            iat + ttl
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
end
