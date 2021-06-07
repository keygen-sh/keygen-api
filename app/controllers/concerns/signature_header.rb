# frozen_string_literal: true

module SignatureHeader
  extend ActiveSupport::Concern

  SUPPORTED_SIGNATURE_ALGORITHMS = %w[ed25519 rsa-pss-sha256 rsa-sha256].freeze
  DEFAULT_SIGNATURE_ALGORITHM    = 'ed25519'.freeze
  DEFAULT_ACCEPT_SIGNATURE       = %(algorithm="#{DEFAULT_SIGNATURE_ALGORITHM}").freeze
  ACCEPT_SIGNATURE_REGEX         =
    %r{
      \A
      (keyid="(?<keyid>[^"]+)")?
      (\s*,\s*)?
      (algorithm="(?<algorithm>[^"]+)")
      (\s*;\s*)?
      \z
    }xi.freeze

  LEGACY_SIGNATURE_UNTIL =
    if Rails.env.production?
      Time.parse('2021-06-07T00:00:00.000Z').freeze
    else
      Time.parse('2552-01-01T00:00:00.000Z').freeze
    end

  attr_reader :signature_algorithm

  def generate_response_signature(algorithm:, account:, date:, method:, uri:, body:)
    signing_data, digest = generate_response_signing_data_and_digest(
      date: date,
      method: method,
      uri: uri,
      body: body,
    )

    signature = sign_response_data(
      algorithm: algorithm,
      account: account,
      data: signing_data,
    )

    [
      %(keyid="#{account.id}", algorithm="#{algorithm}", signature="#{signature}", headers="(request-target) digest date"),
      digest,
    ]
  end

  def validate_accept_signature_header
    accept_signature = request.headers['Keygen-Accept-Signature'].presence || DEFAULT_ACCEPT_SIGNATURE
    signature_params = parse_accept_signature(accept_signature)

    @signature_algorithm ||= signature_params[:algorithm]
  end

  def add_signature_header
    return if
      current_account.nil?

    body = response.body
    date = Time.current

    # NOTE(ezekg) Legacy signatures are deprecated
    response.headers['X-Signature'] = sign_response_data(algorithm: :legacy, account: current_account, data: body) if
      current_account.created_at < LEGACY_SIGNATURE_UNTIL

    # Ensure that the date header matches date in signature
    response.headers['Date'] = date.httpdate

    # Skip non-legacy signature header if algorithm is invalid
    return if
      signature_algorithm.nil?

    # Depending on the algorithm, we may have a digest as well
    sig, digest = generate_response_signature(
      algorithm: signature_algorithm,
      account: current_account,
      date: date,
      method: request.method,
      uri: request.original_fullpath,
      body: body,
    )

    response.headers['Digest']           = "SHA-256=#{digest}"
    response.headers['Keygen-Signature'] = sig
  rescue => e
    Keygen.logger.exception(e)
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

  def generate_response_signing_data_and_digest(date:, method:, uri:, body:)
    digest = sign_with_sha256(data: body)
    data   = [
      "(request-target): #{method.downcase} #{uri}",
      "digest: #{digest}",
      "date: #{date.httpdate}",
    ].join('\n')

    [data, digest]
  end

  def parse_accept_signature(accept_signature)
    data = ACCEPT_SIGNATURE_REGEX.match(accept_signature)

    raise Keygen::Error::BadRequestError, 'invalid accept-signature header (malformed)' unless
      data.present?

    raise Keygen::Error::BadRequestError, 'invalid accept-signature header (unsupported algorithm)' unless
      supports_signature_algorithm?(data[:algorithm])

    raise Keygen::Error::BadRequestError, 'invalid accept-signature header (keyid not found)' if
      data[:keyid].present? && data[:keyid] != current_account.id

    data
  end

  def supports_signature_algorithm?(algorithm)
    SUPPORTED_SIGNATURE_ALGORITHMS.include?(algorithm.to_s.downcase)
  end

  def sign_with_sha256(data:)
    sha256 = OpenSSL::Digest::SHA256.new
    digest = sha256.digest(data)

    Base64.strict_encode64(digest)
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
