# frozen_string_literal: true

module Cookies
  extend ActiveSupport::Concern

  include ActionController::Cookies

  def set_session_id_cookie(session, **)
    set_session_cookie(session_id_cookie_for(session.environment), session:, **)
  end

  def unset_session_id_cookies(**)
    unset_session_cookie(session_id_cookie_for(nil), **)
    unset_session_cookie(session_id_cookie_for(current_environment), **)
  end

  private

  def session_id_cookie_for(environment)
    if environment.present?
      :"session_id.#{environment.id}"
    else
      :session_id
    end
  end

  def set_session_cookie(name, session:, skip_verify_origin: false)
    return unless
      skip_verify_origin || request.origin == Keygen::Portal::ORIGIN

    cookies.encrypted[name] = {
      value: session.id,
      expires: session.expiry,
      domain: Keygen::DOMAIN,
      same_site: :none,
      partitioned: true, # not supported by rack 2 but we have a middleware shim
      httponly: true,
      secure: true,
    }
  end

  def unset_session_cookie(name, skip_verify_origin: false)
    return unless
      skip_verify_origin || request.origin == Keygen::Portal::ORIGIN

    cookies.delete(name,
      domain: Keygen::DOMAIN,
      same_site: :none,
      partitioned: true,
      secure: true,
    )
  end
end
