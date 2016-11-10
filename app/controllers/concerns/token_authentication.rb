module TokenAuthentication
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token::ControllerMethods

  def authenticate_with_token!
    account = current_account ||
      Account.find_by_hashid(params[:account_id] || params[:id])

    authenticate_or_request_with_http_token do |token, options|
      next if account.nil?

      tok = TokenAuthenticationService.new(
        account: account,
        token: token
      ).execute

      if tok&.expired?
        render_unauthorized detail: "is expired", source: {
          pointer: "/data/relationships/token" } and return
      end

      @current_bearer = tok&.bearer
    end
  end

  def authenticate_with_token
    account = current_account ||
      Account.find_by_hashid(params[:account_id] || params[:id])

    authenticate_with_http_token do |token, options|
      next if account.nil?

      tok = TokenAuthenticationService.new(
        account: account,
        token: token
      ).execute

      if tok&.expired?
        render_unauthorized detail: "is expired", source: {
          pointer: "/data/relationships/token" } and return
      end

      @current_bearer = tok&.bearer
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
