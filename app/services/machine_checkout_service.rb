# frozen_string_literal: true

class MachineCheckoutService < AbstractCheckoutService
  class InvalidIncludeError < StandardError; end
  class InvalidMachineError < StandardError; end
  class InvalidLicenseError < StandardError; end

  ALLOWED_INCLUDES = %w[
    license.entitlements
    license.product
    license.policy
    license.user
    license
    components
    environment
    group
  ].freeze

  def initialize(machine:, environment: nil, include: [], **kwargs)
    raise InvalidMachineError, 'machine must be present' unless
      machine.present?

    raise InvalidLicenseError, 'license must be present' unless
      machine.license.present?

    raise InvalidIncludeError, 'invalid includes' if
      (include - ALLOWED_INCLUDES).any?

    @machine     = machine
    @license     = machine.license
    @environment = environment

    super(scheme: machine.license.scheme, include:, **kwargs)
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
    data = renderer.render(machine, meta: meta, include: incl)
                   .to_json

    enc = if encrypted?
            encrypt(data, secret: license.key + machine.fingerprint)
          else
            encode(data, strict: true)
          end
    sig = sign(enc, key: private_key, algorithm: algorithm, prefix: 'machine')

    alg = if encrypted?
            "#{ENCRYPT_ALGORITHM}+#{algorithm}"
          else
            "#{ENCODE_ALGORITHM}+#{algorithm}"
          end

    doc  = { enc: enc, sig: sig, alg: alg }
    enc  = encode(doc.to_json)
    cert = <<~TXT
      -----BEGIN MACHINE FILE-----
      #{enc}
      -----END MACHINE FILE-----
    TXT

    MachineFile.new(
      environment_id: environment&.id,
      account_id: account.id,
      license_id: license.id,
      machine_id: machine.id,
      certificate: cert,
      issued_at: issued_at,
      expires_at: expires_at,
      ttl: ttl,
      includes: incl,
    )
  end

  private

  attr_reader :environment,
              :machine,
              :license

  def private_key
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
  end

  def algorithm
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
  end
end
