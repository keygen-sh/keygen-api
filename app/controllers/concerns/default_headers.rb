module DefaultHeaders
  extend ActiveSupport::Concern

  include CurrentAccountScope
  include SignatureHeaders
  include RateLimiting

  included do
    before_action :validate_accept_and_add_content_type_headers!

    # NOTE(ezekg Run signature header validations after current account has been set, but
    #            before the controller action is processed.
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

      # Skip accept header enforcement for artifacts#show so that we play
      # nicely with package managers such as pip
      render_bad_request(detail: "The content type of the request is not supported (check accept header)", code: 'ACCEPT_INVALID') unless
        artifact_route? || checkout_route?

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
    add_cache_control_headers
    add_signature_headers
    add_whoami_headers
    add_environment_header
    add_license_header
    add_edition_header
    add_mode_header
    add_version_header
    add_powered_by_header
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

  def add_cache_control_headers
    response.headers['Cache-Control'] = 'no-store, max-age=0'
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
    response.headers['Keygen-Account-Id'] = current_account&.id
    response.headers['Keygen-Bearer-Id']  = current_bearer&.id
    response.headers['Keygen-Token-Id']   = current_token&.id
  rescue => e
    Keygen.logger.exception e
  end

  def add_environment_header
    response.headers['Keygen-Environment'] = current_environment&.code
  end

  def add_license_header
    response.headers['Keygen-License'] = Keygen.ee do |key, lic|
      %(id="#{key.id}", iss="#{lic.issued}", exp="#{lic.expiry}")
    end
  end

  def add_edition_header
    response.headers['Keygen-Edition'] = Keygen.edition
  end

  def add_mode_header
    response.headers['Keygen-Mode'] = Keygen.mode
  end

  def add_version_header
    response.headers['Keygen-Version'] = current_api_version
  end

  def add_powered_by_header
    response.headers['X-Powered-By'] = 'Ruby, Rails, and a lot of coffee. (And the occasional Islay.)'
  end

  def artifact_route?
    controller = params[:controller]
    action     = params[:action]

    controller.ends_with?('/release_artifacts') &&
      action == 'show'
  end

  def checkout_route?
    controller = params[:controller]
    action     = params[:action]

    controller.ends_with?('/actions/checkouts') &&
      action == 'show'
  end
end
