# frozen_string_literal: true

class AbstractCheckoutService < BaseService
  class InvalidAccountError < StandardError; end
  class InvalidAlgorithmError < StandardError; end
  class InvalidTTLError < StandardError; end

  DEFAULT_ENCRYPTION_ALGORITHM = 'aes-256-gcm'.freeze
  DEFAULT_ENCODING_ALGORITHM   = 'base64'.freeze
  DEFAULT_SIGNING_ALGORITHM    = 'ed25519'.freeze

  ENCRYPTION_ALGORITHMS = %w[aes-256-gcm].freeze
  ENCODING_ALGORITHMS   = %w[base64].freeze
  SIGNING_ALGORITHMS    = %w[
    ed25519
    rsa-pss-sha256
    rsa-sha256
    ecdsa-p256
  ].freeze

  def initialize(account:, encrypt: false, sign: true, algorithm: nil, ttl: 1.month, include: [], api_version: nil)
    raise InvalidAccountError, 'account must be present' unless
      account.present?

    raise InvalidTTLError, 'must be greater than or equal to 3600 (1 hour)' if
      ttl.present? && ttl < 1.hour

    raise InvalidAlgorithmError, 'algorithm must be present' if
      algorithm.present? && algorithm.blank?

    @algorithm = algorithm.presence || begin
      enc = encrypt ? DEFAULT_ENCRYPTION_ALGORITHM : DEFAULT_ENCODING_ALGORITHM
      sig = sign == true || sign.blank? ? DEFAULT_SIGNING_ALGORITHM : sign

      "#{enc}+#{sig}"
    end

    raise InvalidAlgorithmError, 'invalid encoding algorithm' unless
      encryption_algorithm.in?(ENCRYPTION_ALGORITHMS) ||
      encoding_algorithm.in?(ENCODING_ALGORITHMS)

    raise InvalidAlgorithmError, 'invalid signing algorithm' unless
      signing_algorithm.in?(SIGNING_ALGORITHMS)

    @renderer    = Keygen::JSONAPI::Renderer.new(account:, api_version:, context: :checkout)
    @account     = account
    @ttl         = ttl
    @includes    = include
    @private_key = case
                   when ed25519?
                     account.ed25519_private_key
                   when rsa?
                     account.private_key
                   when ecdsa?
                     account.ecdsa_private_key
                   end
  end

  def call
    raise NotImplementedError, '#call must be implemented by a subclass'
  end

  private

  attr_reader :renderer,
              :private_key,
              :algorithm,
              :ttl,
              :includes,
              :account

  def algorithm_parts      = @algorithm_parts      ||= algorithm.split('+', 2)
  def encryption_algorithm = @encryption_algorithm ||= algorithm_parts.first
  def signing_algorithm    = @signing_algorithm    ||= algorithm_parts.second
  alias :encoding_algorithm :encryption_algorithm

  def encrypted? = encryption_algorithm.in?(ENCRYPTION_ALGORITHMS)
  def encoded?   = encoding_algorithm.in?(ENCODING_ALGORITHMS)
  def ed25519?   = signing_algorithm == 'ed25519'
  def rsa?       = signing_algorithm.in?(%w[rsa-pss-sha256 rsa-sha256])
  def ecdsa?     = signing_algorithm == 'ecdsa-p256'
  def ttl?       = ttl.present?

  def encrypt(value, secret:)
    aes = OpenSSL::Cipher.new(encryption_algorithm)
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

  def sign(value, prefix:)
    data = "#{prefix}/#{value}"

    case signing_algorithm
    when 'rsa-pss-sha256'
      rsa = OpenSSL::PKey::RSA.new(private_key)
      sig  = rsa.sign_pss(OpenSSL::Digest::SHA256.new, data, salt_length: :max, mgf1_hash: 'SHA256')
    when 'rsa-sha256'
      rsa = OpenSSL::PKey::RSA.new(private_key)
      sig = rsa.sign(OpenSSL::Digest::SHA256.new, data)
    when 'ed25519'
      ed25519 = Ed25519::SigningKey.new([private_key].pack('H*'))
      sig     = ed25519.sign(data)
    when 'ecdsa-p256'
      ec  = OpenSSL::PKey::EC.new(private_key)
      sig = ec.sign(OpenSSL::Digest::SHA256.new, data)
    else
      raise InvalidAlgorithmError, 'signing algorithm is not supported'
    end

    encode(sig, strict: true)
  end
end
