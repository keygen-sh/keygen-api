module TokenAuthentication
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token::ControllerMethods

  def authenticate_with_token!
    account = @current_account ||
      Account.find_by_hashid(params[:id] || params[:account_id])

    authenticate_or_request_with_http_token do |token, options|
      break if account.nil?

      @current_bearer = TokenAuthenticationService.new(
        account: account,
        token: token
      ).authenticate
    end
  end

  def authenticate_with_token
    account = @current_account ||
      Account.find_by_hashid(params[:id] || params[:account_id])

    authenticate_with_http_token do |token, options|
      break if account.nil?

      @current_bearer = TokenAuthenticationService.new(
        account: account,
        token: token
      ).authenticate
    end
  end

  protected

  def request_http_token_authentication(realm = "Application", message = nil)
    render_unauthorized({
      detail: "must be a valid token",
      source: {
        pointer: "/data/relationships/token"
      }
    })
  end
end
