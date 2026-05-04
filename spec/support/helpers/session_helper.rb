# frozen_string_literal: true

module SessionHelper
  module WorldMethods
    def authenticate_with_session(session, environment: session.environment)
      cookies = session_cookie_pairs_for(session, environment:)

      header "Cookie", cookies.join("; ")
    end

    def authenticate_with_session_id(session_id, environment: nil)
      name = session_cookie_name_for(environment)
      enc  = encrypted_cookie_value(name, session_id)

      header "Cookie", %(#{name}=#{enc})
    end

    private

    def session_cookie_pairs_for(session, environment: session.environment)
      [
        session_cookie_pair_for(session),
        *session.children.flat_map { session_cookie_pairs_for(it) },
      ]
    end

    def session_cookie_pair_for(session, environment: session.environment)
      name = session_cookie_name_for(environment)
      enc  = encrypted_cookie_value(name, session.id)

      %(#{name}=#{enc})
    end

    def session_cookie_name_for(environment)
      environment.present? ? :"session_id.#{environment.id}" : :session_id
    end

    def encrypted_cookie_value(name, value)
      app       = Rails.application
      config    = app.config
      keygen    = app.key_generator
      salt      = config.action_dispatch.authenticated_encrypted_cookie_salt
      cipher    = config.action_dispatch.encrypted_cookie_cipher
      key_len   = ActiveSupport::MessageEncryptor.key_len(cipher)
      key       = keygen.generate_key(salt, key_len)
      encryptor = ActiveSupport::MessageEncryptor.new(key,
        serializer: ActiveSupport::MessageEncryptor::NullSerializer,
        cipher:,
      )

      dec = JSON.dump(value)
      enc = encryptor.encrypt_and_sign(dec, purpose: "cookie.#{name}")

      CGI.escape(enc)
    end
  end
end
