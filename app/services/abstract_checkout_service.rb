# frozen_string_literal: true

class AbstractCheckoutService < BaseService
  class InvalidAlgorithmError < StandardError; end
  class InvalidPrivateKeyError < StandardError; end
  class InvalidTTLError < StandardError; end

  ENCRYPT_ALGORITHM  = 'aes-256-gcm'
  ENCODE_ALGORITHM   = 'base64'
  ALLOWED_ALGORITHMS = %w[
    ed25519
    rsa-pss-sha256
    rsa-sha256
  ]

  def initialize(encrypt:, ttl:, include:)
    raise InvalidPrivateKeyError, 'private key is missing' unless
      private_key.present?

    raise InvalidAlgorithmError, 'algorithm is missing' unless
      algorithm.present?

    raise InvalidTTLError, 'must be greater than or equal to 3600 (1 hour)' if
      ttl.present? && ttl < 1.hour

    @renderer    = Keygen::JSONAPI::Renderer.new(context: :checkout)
    @encrypted   = encrypt
    @ttl         = ttl
    @includes    = include
  end

  def call
    raise NotImplementedError, '#call must be implemented by a subclass'
  end

  private

  attr_reader :renderer,
              :encrypted,
              :ttl,
              :includes

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
    auth_tag   = aes.auth_tag

    [ciphertext, iv, auth_tag]
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
