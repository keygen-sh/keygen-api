module SignatureHeader
  extend ActiveSupport::Concern

  included do
    after_action :add_signature_header
  end

  def add_signature_header
    return if current_account.nil?

    priv = OpenSSL::PKey::RSA.new current_account.private_key
    sig = priv.sign OpenSSL::Digest::SHA512.new, response.body

    response.headers["X-Signature"] = Base64.encode64 sig
  rescue => e
    Raygun.track_exception e
  end
end
