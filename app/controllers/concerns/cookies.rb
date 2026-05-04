# frozen_string_literal: true

module Cookies
  extend ActiveSupport::Concern

  include ActionController::Cookies

  def set_session_cookie(session, skip_verify_origin: false)
    return unless
      skip_verify_origin || request.origin == Keygen::Portal::ORIGIN

    name = session_cookie_name_for(session.environment)

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

  def unset_session_cookies(session, skip_verify_origin: false)
    return unless
      skip_verify_origin || request.origin == Keygen::Portal::ORIGIN

    names = [
      session_cookie_name_for(session&.environment),
      *child_cookie_names_for(session),
    ].uniq

    names.map do |name|
      unset_session_cookie(name, skip_verify_origin:)
    end
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

  private

  def session_cookie_name_for(environment)
    if environment.present?
      :"session_id.#{environment.id}"
    else
      :session_id
    end
  end

  def child_cookie_names_for(session)
    return [] if session.nil?

    session.children.map { session_cookie_name_for(it.environment) }
  end
end
