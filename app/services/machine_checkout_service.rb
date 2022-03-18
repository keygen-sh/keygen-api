# frozen_string_literal: true

class MachineCheckoutService < AbstractCheckoutService
  class InvalidAccountError < StandardError; end
  class InvalidMachineError < StandardError; end
  class InvalidLicenseError < StandardError; end
  class InvalidIncludeError < StandardError; end

  ALLOWED_INCLUDES = %w[
    license.entitlements
    license.policy
    license.user
    license
    product
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

    private_key =
      case machine.license.scheme
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
      case machine.license.scheme
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
            iat + ActiveSupport::Duration.build(ttl)
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

  attr_reader :account,
              :machine
end
