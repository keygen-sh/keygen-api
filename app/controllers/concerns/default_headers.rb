module DefaultHeaders
  extend ActiveSupport::Concern

  include CurrentAccountScope
  include SignatureHeaders
  include RateLimiting

  included do
    # NOTE(ezekg Run header validations after current account has been set, but before
    #            the controller action is processed.
    after_current_account :validate_accept_and_add_content_type_headers!
    after_current_account :validate_accept_signature_header!

    # NOTE(ezekg) We're using an *around* action here to ensure these headers are always
    #             sent, even when an error has halted the action chain.
    around_action :add_default_headers
  end

  private

  def validate_accept_and_add_content_type_headers!
    accepted_content_types = HashWithIndifferentAccess.new(
      jsonapi: Mime::Type.lookup_by_extension(:jsonapi).to_s,
      json: Mime::Type.lookup_by_extension(:json).to_s,
    )

    content_type = request.headers['Accept']&.strip
    if content_type.nil? || content_type.include?('*/*')
      response.headers['Content-Type'] = accepted_content_types[:jsonapi]

      return
    end

    selected_content_types = accepted_content_types.values &
                             content_type.split(/,\s*/)
    if selected_content_types.empty?
      response.headers['Content-Type'] = accepted_content_types[:jsonapi]

      render_bad_request(detail: "The content type of the request is not supported (check accept header)", code: 'ACCEPT_INVALID')

      return
    end

    response.headers['Content-Type'] = selected_content_types.first.strip
  end

  def add_default_headers
    yield
  rescue => e
    # Ensure all exceptions are properly dealt with before we process our
    # signature headers. E.g. rescuing not found errors and rendering
    # a 404. Otherwise, the response body may be blank.
    rescue_with_handler(e) || raise
  ensure
    add_content_security_policy_headers
    add_rate_limiting_headers
    add_signature_headers
    add_whoami_headers
    add_version_header
  end

  def add_content_security_policy_headers
    response.headers['Report-To'] = <<~JSON.squish
      {
        "group": "csp-reports",
        "max_age": 10886400,
        "endpoints": [{
          "url": "https://api.keygen.sh/-/csp-reports"
        }]
      }
    JSON
    response.headers['Content-Security-Policy'] = <<~TXT.squish
      default-src 'none';
      report-uri /-/csp-reports;
      report-to csp-reports;
    TXT
  end

  def add_rate_limiting_headers
    data = rate_limiting_data
    return if data.nil?

    response.headers['X-RateLimit-Window']    = data[:window]
    response.headers['X-RateLimit-Count']     = data[:count]
    response.headers['X-RateLimit-Limit']     = data[:limit]
    response.headers['X-RateLimit-Remaining'] = data[:remaining]
    response.headers['X-RateLimit-Reset']     = data[:reset]
  rescue => e
    Keygen.logger.exception e
  end

  def add_whoami_headers
    response.headers['Keygen-Account-Id'] = current_account&.id if
      current_account&.id.present?
    response.headers['Keygen-Bearer-Id'] = current_bearer&.id if
      current_bearer&.id.present?
    response.headers['Keygen-Token-Id'] = current_token&.id if
      current_token&.id.present?
  rescue => e
    Keygen.logger.exception e
  end

  def add_version_header
    response.headers['Keygen-Version'] = '1.0'
  end
end
