# frozen_string_literal: true

class AbstractCheckoutService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidAlgorithmError < StandardError; end
  class InvalidTTLError < StandardError; end

  ENCRYPT_ALGORITHM  = 'aes-256-gcm'.freeze
  ENCODE_ALGORITHM   = 'base64'.freeze
  ALLOWED_ALGORITHMS = %w[
    ed25519
    rsa-pss-sha256
    rsa-sha256
  ].freeze

  def initialize(account:, scheme: nil, encrypt: false, ttl: 1.month, include: [], api_version: nil)
    raise InvalidAccountError, 'license must be present' unless
      account.present?

    raise InvalidTTLError, 'must be greater than or equal to 3600 (1 hour)' if
      ttl.present? && ttl < 1.hour

    @renderer    = Keygen::JSONAPI::Renderer.new(account:, api_version:, context: :checkout)
    @account     = account
    @encrypted   = encrypt
    @ttl         = ttl
    @includes    = include
    @private_key = case scheme
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

    @algorithm = case scheme
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

  def call
    raise NotImplementedError, '#call must be implemented by a subclass'
  end

  private

  attr_reader :renderer,
              :private_key,
              :algorithm,
              :encrypted,
              :ttl,
              :includes,
              :account

  def encrypted?
    !!encrypted
  end

  def encoded?
    !encrypted?
  end

  def ttl?
    ttl.present?
  end

  def encrypt(value, secret:)
    aes = OpenSSL::Cipher.new(ENCRYPT_ALGORITHM)
    aes.encrypt

    key = OpenSSL::Digest::SHA256.digest(secret)
    iv  = aes.random_iv

    aes.key = key
    aes.iv  = iv

    ciphertext = aes.update(value) + aes.final
    tag        = aes.auth_tag

    [ciphertext, iv, tag]
      .map { encode(_1, strict: true) }
      .join('.')
  end

  def encode(value, strict: false)
    enc = if strict
            Base64.strict_encode64(value)
          else
            Base64.encode64(value)
          end

    enc.chomp
  end

  def sign(value, key:, algorithm:, prefix:)
    raise InvalidAlgorithmError, 'algorithm is invalid' unless
      ALLOWED_ALGORITHMS.include?(algorithm)

    data = "#{prefix}/#{value}"

    case algorithm
    when 'rsa-pss-sha256'
      rsa = OpenSSL::PKey::RSA.new(key)
      sig  = rsa.sign_pss(OpenSSL::Digest::SHA256.new, data, salt_length: :max, mgf1_hash: 'SHA256')
    when 'rsa-sha256'
      rsa = OpenSSL::PKey::RSA.new(key)
      sig = rsa.sign(OpenSSL::Digest::SHA256.new, data)
    when 'ed25519'
      ed25519 = Ed25519::SigningKey.new([key].pack('H*'))
      sig     = ed25519.sign(data)
    else
      raise InvalidAlgorithmError, 'signing scheme is not supported'
    end

    encode(sig, strict: true)
  end
end
