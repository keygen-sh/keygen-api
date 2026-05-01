# frozen_string_literal: true

module SessionHelper
  module WorldMethods
    def authenticate_with_session(session, environment: session.environment)
      set_session_cookie_header(session_cookie_name_for(environment), session.id)
    end

    def set_session_cookie_header(name, value)
      enc = encrypted_cookie_value(name, value)

      header "Cookie", %(#{name}=#{enc})
    end

    private

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
