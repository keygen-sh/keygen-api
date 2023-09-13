# frozen_string_literal: true

module SignatureHeaders
  extend ActiveSupport::Concern

  include CurrentAccountScope
  include SignatureMethods

  DEFAULT_ACCEPT_SIGNATURE = %(algorithm="#{SignatureMethods::DEFAULT_SIGNATURE_ALGORITHM}").freeze
  LEGACY_SIGNATURE_UNTIL   =
    if Rails.env.production?
      Time.parse('2021-06-11T00:00:00.000Z').freeze
    else
      Time.parse('2552-01-01T00:00:00.000Z').freeze
    end

  included do
    # NOTE(ezekg Run signature header validations after current account has been set, but
    #            before the controller action is processed.
    after_current_account :validate_accept_signature_header!

    # NOTE(ezekg) We're using an *around* action here to ensure these headers are always
    #             sent, even when an error has halted the action chain.
    around_action :add_signature_headers
  end

  def add_signature_headers
    yield
  rescue => e
    # Ensure all exceptions are properly dealt with before we process our
    # signature headers. E.g. rescuing not found errors and rendering
    # a 404. Otherwise, the response body may be blank.
    rescue_with_handler(e) || raise
  ensure
    generate_signature_headers
  end

  private

  def validate_accept_signature_header!
    return if
      current_account.nil?

    accept_signature = request.headers['Keygen-Accept-Signature'].presence || DEFAULT_ACCEPT_SIGNATURE
    data = parse_accept_signature_header(accept_signature)

    raise Keygen::Error::BadRequestError, 'invalid accept-signature header (malformed)' unless
      data.present?

    raise Keygen::Error::BadRequestError, 'invalid accept-signature header (unsupported algorithm)' unless
      supports_signature_algorithm?(data[:algorithm])

    raise Keygen::Error::BadRequestError, 'invalid accept-signature header (keyid not found)' if
      data[:keyid].present? && data[:keyid] != current_account.id
  end

  def generate_signature_headers
    return if
      current_account.nil?

    body     = response.body
    date     = Time.current
    httpdate = date.httpdate

    # NOTE(ezekg) Legacy signatures are deprecated and only show for old accounts
    response.headers['X-Signature'] = sign_response_data(algorithm: :legacy, account: current_account, data: body) if
      current_account.created_at < LEGACY_SIGNATURE_UNTIL

    # Skip non-legacy signature header if algorithm is invalid
    accept_signature = request.headers['Keygen-Accept-Signature'].presence || DEFAULT_ACCEPT_SIGNATURE
    signature_params = parse_accept_signature_header(accept_signature)
    return unless
      signature_params.present?

    algorithm = signature_params[:algorithm]
    keyid     = signature_params[:keyid]
    return unless
      algorithm.present? && supports_signature_algorithm?(algorithm)

    # Depending on the algorithm, we may have a digest as well
    digest = generate_digest_header(body: body)
    sig    = generate_signature_header(
      account: current_account,
      algorithm: algorithm,
      keyid: keyid,
      date: httpdate,
      method: request.method,
      host: request.host,
      uri: request.original_fullpath,
      digest: digest,
    )

    response.headers['Date']             = httpdate
    response.headers['Digest']           = digest
    response.headers['Keygen-Signature'] = sig if sig.present?

    # For debugging purposes
    response.headers['Keygen-Date']   = httpdate
    response.headers['Keygen-Digest'] = digest
  rescue => e
    puts e
    Keygen.logger.exception(e)
  end
end
