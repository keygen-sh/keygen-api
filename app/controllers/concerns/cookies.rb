# frozen_string_literal: true

module Cookies
  extend ActiveSupport::Concern

  include ActionController::Cookies

  def set_session_id_cookie(session)
    return unless
      request.origin == Keygen::Portal::ORIGIN

    cookies.encrypted[:session_id] = {
      value: session.id,
      expires: session.expiry,
      domain: Keygen::DOMAIN,
      same_site: :none,
      partitioned: true, # not supported by rack 2 but we have a middleware shim
      httponly: true,
      secure: true,
    }
  end

  def reset_session_id_cookie
    return unless
      request.origin == Keygen::Portal::ORIGIN

    cookies.delete(:session_id,
      domain: Keygen::DOMAIN,
      same_site: :none,
      partitioned: true,
    )
  end
end
