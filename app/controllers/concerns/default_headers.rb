# frozen_string_literal: true

module DefaultHeaders
  extend ActiveSupport::Concern

  include RateLimiting

  included do
    # NOTE(ezekg) We're using an *around* action here to ensure these headers are always
    #             sent, even when an error has halted the action chain.
    around_action :add_default_headers
  end

  private

  def add_default_headers
    yield
  rescue => e
    rescue_with_handler(e) || raise
  ensure
    add_content_security_policy_headers
    add_rate_limiting_headers
    add_cache_control_headers
    add_whoami_headers
    add_environment_header
    add_license_header
    add_edition_header
    add_mode_header
    add_revision_header
    add_version_header
    add_powered_by_header
  end

  def add_content_security_policy_headers
    response.headers['Report-To'] = <<~JSON.squish
      {
        "group": "csp-reports",
        "max_age": 10886400,
        "endpoints": [{
          "url": "https://#{ENV.fetch('KEYGEN_HOST')}/-/csp-reports"
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
    response.headers['Cache-Control'] = 'no-transform, no-store, max-age=0'
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
    Keygen.logger.exception(e)
  end

  def add_whoami_headers
    response.headers['Keygen-Account'] = current_account&.id
    response.headers['Keygen-Bearer']  = current_bearer&.id
    response.headers['Keygen-Token']   = current_token&.id
  rescue => e
    Keygen.logger.exception(e)
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

  def add_revision_header
    response.headers['Keygen-Revision'] = Keygen.revision
  end

  def add_version_header
    response.headers['Keygen-Version'] = current_api_version
  end

  def add_powered_by_header
    response.headers['X-Powered-By'] = 'Ruby, Rails, and a lot of coffee. (And the occasional Islay.)'
  end
end
