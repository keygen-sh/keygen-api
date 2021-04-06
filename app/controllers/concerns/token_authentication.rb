# frozen_string_literal: true

module TokenAuthentication
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token::ControllerMethods

  def authenticate_with_token!
    @current_bearer = authenticate_or_request_with_http_token &method(:authenticator)
  end

  def authenticate_with_token
    @current_bearer = authenticate_with_http_token &method(:authenticator)
  end

  private

  attr_accessor :current_token_value

  def authenticator(token, options)
    return if current_account.nil?

    # Make sure token matches our expected format. This is also here to help users
    # who may be mistakenly using a UUID as a token, which is a common mistake.
    if token.present? && token =~ UUID_REGEX
      render_unauthorized code: 'TOKEN_FORMAT_INVALID', detail: "Token format is invalid (make sure the token begins with a proper prefix e.g. 'prod-XXX' or 'acti-XXX', and that it's not a token UUID)" and return
    end

    @current_token_value = token
    @current_token = TokenAuthenticationService.new(
      account: current_account,
      token: token
    ).execute

    current_bearer = current_token&.bearer

    if (current_bearer.present? && current_bearer.account_id != current_account.id) ||
       (current_token.present? && current_token.account_id != current_account.id)
      Keygen.logger.error "[authentication] Account mismatch: account=#{current_account&.id || 'N/A'} token=#{current_token&.id || 'N/A'} bearer=#{current_bearer&.id || 'N/A'}"

      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID')
    end

    Keygen::Store::Request.store[:current_token] = current_token
    Keygen::Store::Request.store[:current_bearer] = current_bearer

    if current_token&.expired?
      render_unauthorized code: 'TOKEN_EXPIRED', detail: "Token is expired" and return
    end

    current_token&.bearer
  end

  def request_http_token_authentication(realm = "Keygen", message = nil)
    headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")

    case
    when current_token_value.nil?
      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_BLANK')
    else
      raise Keygen::Error::UnauthorizedError.new(code: 'TOKEN_INVALID')
    end
  end
end
