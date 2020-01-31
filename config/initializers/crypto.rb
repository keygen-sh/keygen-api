# frozen_string_literal: true

require_relative "../../lib/keygen/enumable"

RSA_KEY_SIZE = 2048
RSA_MAX_BYTE_SIZE = RSA_KEY_SIZE / 8 - 11

DSA_KEY_SIZE = 2048

ECDSA_GROUP = "secp256k1"

CRYPTO_SCHEMES = %w[
  LEGACY_ENCRYPT
  RSA_2048_PKCS1_ENCRYPT
  RSA_2048_PKCS1_SIGN
  RSA_2048_PKCS1_PSS_SIGN
  RSA_2048_JWT_RS256
  DSA_2048_SIGN
  ECDSA_SECP256K1_SIGN
].freeze

module Crypto
  extend Enumable

  define_singleton_enum :schemes, CRYPTO_SCHEMES.each_with_object({}) { |k, h| h[k.downcase] = k }
end