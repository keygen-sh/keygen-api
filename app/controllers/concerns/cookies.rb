# frozen_string_literal: true

module Cookies
  extend ActiveSupport::Concern

  include ActionController::Cookies

  def set_session_id_cookie(session)
    return unless session in Session # nice

    cookies.encrypted[:session_id] = {
      value: session.id,
      expires: session.expiry,
      domain: Keygen::DOMAIN,
      same_site: :none,
      httponly: true,
      secure: true,
    }
  end

  def reset_session_id_cookie
    cookies.delete(:session_id,
      domain: Keygen::DOMAIN,
      same_site: :none,
    )
  end
end
