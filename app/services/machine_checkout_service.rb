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

    kwargs.merge!(license: machine.license)

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
      -----BEGIN MACHINE FILE-----
      #{enc}
      -----END MACHINE FILE-----
    TXT
  end

  private

  attr_reader :machine
end
