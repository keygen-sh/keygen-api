# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token::ControllerMethods
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  def authenticate_with_token!
    @current_bearer =
      case
      when has_bearer_credentials?
        authenticate_or_request_with_http_token(&method(:http_token_authenticator))
      when has_basic_credentials?
        authenticate_or_request_with_http_basic(&method(:http_basic_authenticator))
      when has_license_credentials?
        authenticate_or_request_with_http_license(&method(:http_license_authenticator))
      else
        authenticate_or_request_with_query_token(&method(:query_token_authenticator))
      end
  end

  def authenticate_with_token
    @current_bearer =
      case
      when has_bearer_credentials?
        authenticate_with_http_token(&method(:http_token_authenticator))
      when has_basic_credentials?
        authenticate_with_http_basic(&method(:http_basic_authenticator))
      when has_license_credentials?
        authenticate_with_http_license(&method(:http_license_authenticator))
      else
        authenticate_with_query_token(&method(:query_token_authenticator))
      end
  end

  private

  def authenticate_or_request_with_query_token(&auth_procedure)
    authenticate_with_query_token(&auth_procedure) || request_http_token_authentication
  end

  def authenticate_with_query_token(&auth_procedure)
    query_token = request.query_parameters[:token] ||
                  request.query_parameters[:auth]

    auth_procedure.call(query_token)
  end

  def authenticate_or_request_with_http_license(&auth_procedure)
    authenticate_with_http_license(&auth_procedure) || request_http_token_authentication
  end

  def authenticate_with_http_license(&auth_procedure)
    license_key = request.authorization.to_s.split(' ', 2).second

    auth_procedure.call(license_key)
  end

  def query_token_authenticator(query_token)
    return nil if
      current_account.nil? || query_token.blank?

    username, password = query_token.split(':', 2)

    case username
    when 'license'
      http_license_authenticator(password)
    when 'token'
      http_token_authenticator(password)
    else
      # NOTE(ezekg) For backwards compatibility
      http_token_authenticator(username)
    end
  end

  def http_basic_authenticator(username = nil, password = nil)
    return nil if
      current_account.nil? || username.blank? && password.blank?

    case username
    when 'license'
      http_license_authenticator(password)
    when 'token'
      http_token_authenticator(password)
    else
      # NOTE(ezekg) For backwards compatibility
      http_token_authenticator(username)
    end
  end

  def http_token_authenticator(http_token = nil, options = nil)
    return nil if
      current_account.nil? || http_token.blank?

    # Make sure token matches our expected format. This is also here to help users
    # who may be mistakenly using a UUID as a token, which is a common mistake.
    if http_token.present? && http_token =~ UUID_RE
      raise Keygen::Error::UnauthorizedError.new(
        detail: "Token format is invalid (make sure that you're providing a token value, not a token's UUID identifier)",
        code: 'TOKEN_FORMAT_INVALID',
      )
    end

    @current_http_scheme = :token
    @current_http_token  = http_token
    @current_token       = TokenAuthenticationService.call(
      account: current_account,
      token: http_token
    )

    # If a token was provided but was not found, fail early.
    raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID') if
      http_token.present? &&
      current_token.nil?

    current_bearer = current_token&.bearer

    # Sanity check
    if (current_bearer.present? && current_bearer.account_id != current_account.id) ||
       (current_token.present? && current_token.account_id != current_account.id)
      Keygen.logger.error "[authentication] Account mismatch: account=#{current_account&.id || 'N/A'} token=#{current_token&.id || 'N/A'} bearer=#{current_bearer&.id || 'N/A'}"

      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID')
    end

    Current.bearer = current_bearer
    Current.token  = current_token

    raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_EXPIRED', detail: 'Token is expired') if
      current_token&.expired?

    raise Keygen::Error::ForbiddenError.new(code: 'USER_BANNED', detail: 'User is banned') if
      current_bearer.respond_to?(:banned?) &&
      current_bearer.banned?

    case
    when current_bearer&.has_role?(:license)
      raise Keygen::Error::ForbiddenError.new(code: 'TOKEN_NOT_ALLOWED', detail: 'Token authentication is not allowed by policy') unless
        current_bearer.supports_token_auth?
    end

    current_bearer
  end

  def http_license_authenticator(license_key, options = nil)
    return nil if
      current_account.nil? || license_key.blank?

    @current_http_scheme = :license
    @current_http_token  = license_key
    @current_token       = nil

    current_license = LicenseKeyLookupService.call(
      account: current_account,
      key: license_key,
    )

    # Fail early if license key was provided but not found
    raise Keygen::Error::UnauthorizedError.new(code: 'LICENSE_INVALID') if
      license_key.present? &&
      current_license.nil?

    # Sanity check
    if current_license.present? && current_license.account_id != current_account.id
     Keygen.logger.error "[authentication] Account mismatch: account=#{current_account&.id || 'N/A'} license=#{current_license&.id || 'N/A'}"

     raise Keygen::Error::UnauthorizedError.new(code: 'LICENSE_INVALID')
    end

    Current.bearer = current_license

    if current_license.present?
      raise Keygen::Error::ForbiddenError.new(code: 'LICENSE_BANNED', detail: 'License is banned') if
        current_license.banned?

      raise Keygen::Error::ForbiddenError.new(code: 'LICENSE_SUSPENDED', detail: 'License is suspended') if
        current_license.suspended?

      raise Keygen::Error::ForbiddenError.new(code: 'LICENSE_EXPIRED', detail: 'License is expired') if
        current_license.revoke_access? &&
        current_license.expired?

      raise Keygen::Error::ForbiddenError.new(code: 'LICENSE_NOT_ALLOWED', detail: 'License key authentication is not allowed by policy') unless
        current_license.supports_license_auth?
    end

    current_license
  end

  def request_http_token_authentication(realm = 'keygen', message = nil)
    headers['WWW-Authenticate'] = %(Bearer realm="#{realm.gsub(/"/, "")}")

    case
    when current_http_token.blank?
      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_MISSING')
    else
      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID')
    end
  end

  def request_http_basic_authentication(realm = 'keygen', message = nil)
    headers['WWW-Authenticate'] = %(Bearer realm="#{realm.gsub(/"/, "")}")

    raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID')
  end

  def has_bearer_credentials?
    authentication_scheme == 'bearer' || authentication_scheme == 'token'
  end

  def has_basic_credentials?
    authentication_scheme == 'basic'
  end

  def has_license_credentials?
    authentication_scheme == 'license'
  end

  def authentication_scheme
    return nil unless
      request.authorization.present?

    auth_parts  = request.authorization.to_s.split(' ', 2)
    auth_scheme = auth_parts.first
    return nil if
      auth_scheme.nil?

    auth_scheme.downcase
  end
end
