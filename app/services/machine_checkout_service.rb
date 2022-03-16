# frozen_string_literal: true

class MachineCheckoutService < AbstractCheckoutService
  ALLOWED_INCLUDES = %w[
    license.entitlements
    license.policy
    license.user
    license
    product
    group
  ]

  def initialize(machine:, **kwargs)
    @machine = machine

    kwargs[:algorithm] ||=
      case machine.license.scheme
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
    data = renderer.render(machine, include: includes & ALLOWED_INCLUDES)
                   .to_json

    enc = if encrypted?
            encrypt(data, secret: machine.fingerprint)
          else
            encode(data, strict: true)
          end
    sig = sign(enc, prefix: 'machine')

    alg = if encrypted?
            "#{ENCRYPT_ALGORITHM}+#{algorithm}"
          else
            "#{ENCODE_ALGORITHM}+#{algorithm}"
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
      -----BEGIN MACHINE FILE-----
      #{enc}
      -----END MACHINE FILE-----
    TXT
  end

  private

  attr_reader :machine
end
