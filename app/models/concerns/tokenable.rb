# frozen_string_literal: true

module Tokenable
  # NOTE(ezekg) Remember to update tests to sample from new versions when changed
  ALGO_VERSION = "v3"

  extend ActiveSupport::Concern

  def generate_token(attribute, length: 64, version: ALGO_VERSION)
    loop do
      token = SecureRandom.hex(length).gsub /.{#{version.length}}\z/, version
      token = yield token if block_given?
      break token unless self.class.exists? attribute => token
    end
  end

  def generate_hashed_token(attribute, length: 64, version: ALGO_VERSION)
    loop do
      raw = nil
      res = nil

      case version
      when "v1"
        raw = SecureRandom.hex(length).gsub /.{#{version.length}}\z/, version
        raw = yield raw if block_given?

        # We're hashing with SHA256 first so that we can bypass Bcrypt's 72 max
        # length, since the first 66 chars of our string consist of the account
        # and the bearer's UUID. This lets us use larger tokens (as seen here)
        # and avoid the nasty truncation.
        res = BCrypt::Password.create Digest::SHA256.digest(raw)
      when "v2"
        raw = SecureRandom.hex(length).gsub /.{#{version.length}}\z/, version
        raw = yield raw if block_given?

        res = OpenSSL::HMAC.hexdigest "SHA512", account.private_key, raw
      when "v3"
        raw = SecureRandom.hex(length) + version
        raw = yield raw if block_given?

        res = OpenSSL::HMAC.hexdigest "SHA256", account.secret_key, raw
      else
        raise NotImplementedError.new "token #{version} not implemented"
      end

      break [raw, res] unless self.class.exists? attribute => res
    end
  end

  # See: https://github.com/plataformatec/devise/blob/88724e10adaf9ffd1d8dbfbaadda2b9d40de756a/lib/devise/encryptor.rb?ts=2#L12
  def compare_hashed_token(attribute, token, version: ALGO_VERSION)
    return false if token.blank?

    a = self.send attribute
    b = nil

    case version
    when "v1"
      bcrypt = BCrypt::Password.new a
      digest = Digest::SHA256.digest(token)

      if digest.include?("\x00") # null byte
        Keygen.logger.warn { "[tokenable] v1 token must be regenerated: tokenable_type=#{self.class.name.inspect} tokenable_id=#{id.inspect} tokenable_attr=#{attribute.inspect}" }
      end

      b = BCrypt::Engine.hash_secret digest, bcrypt.salt
    when "v2"
      b = OpenSSL::HMAC.hexdigest "SHA512", account.private_key, token
    when "v3"
      b = OpenSSL::HMAC.hexdigest "SHA256", account.secret_key, token
    else
      raise NotImplementedError.new "token #{version} not implemented"
    end

    secure_compare a, b
  rescue
    false
  end

  private

  # Constant-time comparison algorithm to prevent timing attacks
  # See: https://github.com/plataformatec/devise/blob/7b000390a066d89b9cc474b22aa8afff6f5c85b7/lib/devise.rb?ts=2#L485
  def secure_compare(a, b)
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize
    l = a.unpack "C#{a.bytesize}"

    res = 0
    b.each_byte { |byte| res |= byte ^ l.shift }

    res == 0
  end
end
