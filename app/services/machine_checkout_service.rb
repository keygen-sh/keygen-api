# frozen_string_literal: true

class MachineCheckoutService < AbstractCheckoutService
  class InvalidAccountError < StandardError; end
  class InvalidMachineError < StandardError; end
  class InvalidLicenseError < StandardError; end
  class InvalidIncludeError < StandardError; end

  ALLOWED_INCLUDES = %w[
    license.entitlements
    license.product
    license.policy
    license.user
    license
    group
  ]

  def initialize(account:, machine:, encrypt: false, ttl: 1.month, include: [])
    raise InvalidAccountError, 'account must be present' unless
      account.present?

    raise InvalidMachineError, 'machine must be present' unless
      machine.present?

    raise InvalidLicenseError, 'license must be present' unless
      machine.license.present?

    raise InvalidIncludeError, 'invalid includes' if
      (include - ALLOWED_INCLUDES).any?

    @account = account
    @machine = machine
    @license = machine.license

    super(encrypt: encrypt, ttl: ttl, include: include)
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
    data = renderer.render(machine, meta: meta, include: incl)
                   .to_json

    enc = if encrypted?
            encrypt(data, secret: machine.fingerprint)
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
      account_id: account.id,
      license_id: license.id,
      machine_id: machine.id,
      certificate: cert,
      issued_at: iat,
      expires_at: exp,
      ttl: ttl,
    )
  end

  private

  attr_reader :account,
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
