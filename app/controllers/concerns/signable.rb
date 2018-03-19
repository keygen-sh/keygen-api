module Signable
  extend ActiveSupport::Concern

  def sign(key:, data:)
    priv = OpenSSL::PKey::RSA.new key
    sig = priv.sign OpenSSL::Digest::SHA256.new, data

    # We're using strict_encode64 here because encode64 adds a newline every
    # 60 chars, which creates invalid signature headers.
    Base64.strict_encode64 sig
  rescue => e
    Raygun.track_exception e
  end
end