# frozen_string_literal: true

module SignatureMethods
  extend ActiveSupport::Concern

  SUPPORTED_SIGNATURE_ALGORITHMS = %w[ed25519 rsa-pss-sha256 rsa-sha256].freeze
  DEFAULT_SIGNATURE_ALGORITHM    = 'ed25519'.freeze
  ACCEPT_SIGNATURE_RE            =
    %r{
      \A
      (keyid="(?<keyid>[^"]+)")?
      (\s*,\s*)?
      (algorithm="(?<algorithm>[^"]+)")
      (\s*;\s*)?
      \z
    }xi.freeze

  def generate_digest_header(body:)
    sha256 = OpenSSL::Digest::SHA256.new
    digest = sha256.digest(body.presence || '')
    enc    = Base64.strict_encode64(digest)

    "sha-256=#{enc}"
  end

  # See: https://tools.ietf.org/id/draft-cavage-http-signatures-08.html#rfc.section.4
  def generate_signature_header(account:, algorithm:, keyid:, date:, method:, host:, uri:, digest:)
    return nil if
      account.nil?

    return nil if
      keyid.present? && account.id != keyid

    signing_data = generate_signing_data(
      date: date,
      method: method,
      host: host,
      uri: uri,
      digest: digest,
    )

    signature = sign_response_data(
      algorithm: algorithm,
      account: account,
      data: signing_data,
    )

    %(keyid="#{account.id}", algorithm="#{algorithm}", signature="#{signature}", headers="\(request-target\) host date digest")
  end

  def sign_response_data(algorithm:, account:, data:)
    return nil if algorithm.nil? || account.nil?

    case algorithm.to_s.downcase
    when 'ed25519'
      sign_with_ed25519(key: account.ed25519_private_key, data: data.to_s)
    when 'rsa-pss-sha256'
      sign_with_rsa_pkcs1_pss(key: account.private_key, data: data.to_s)
    when 'rsa-sha256',
         'legacy'
      sign_with_rsa_pkcs1(key: account.private_key, data: data.to_s)
    end
  rescue => e
    Keygen.logger.exception e

    nil
  end

  private

  # NOTE(ezekg) We're using strict_encode64 because encode64 adds a newline
  #             every 60 chars, which results in an invalid HTTP header.

  def generate_signing_data(date:, method:, host:, uri:, digest:)
    data = [
      "(request-target): #{method.downcase} #{uri.presence || '/'}",
      "host: #{host}",
      "date: #{date}",
      "digest: #{digest}",
    ]

    data.join("\n")
  end

  def parse_accept_signature_header(accept_signature)
    ACCEPT_SIGNATURE_RE.match(accept_signature)
  end

  def supports_signature_algorithm?(algorithm)
    SUPPORTED_SIGNATURE_ALGORITHMS.include?(algorithm.to_s.downcase)
  end

  def sign_with_ed25519(key:, data:)
    key_bytes = [key].pack('H*')
    priv      = Ed25519::SigningKey.new(key_bytes)
    sig       = priv.sign(data)

    Base64.strict_encode64(sig)
  end

  def sign_with_rsa_pkcs1_pss(key:, data:)
    digest = OpenSSL::Digest::SHA256.new
    priv   = OpenSSL::PKey::RSA.new(key)
    sig    = priv.sign_pss(digest, data, salt_length: :max, mgf1_hash: 'SHA256')

    Base64.strict_encode64(sig)
  end

  def sign_with_rsa_pkcs1(key:, data:)
    digest = OpenSSL::Digest::SHA256.new
    priv   = OpenSSL::PKey::RSA.new(key)
    sig    = priv.sign(digest, data)

    Base64.strict_encode64(sig)
  end
end
