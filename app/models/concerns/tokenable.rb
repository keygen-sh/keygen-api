module Tokenable
  extend ActiveSupport::Concern

  def generate_token(attribute)
    loop do
      token = SecureRandom.hex 32
      token = yield token if block_given?
      break token unless self.class.exists? attribute => token
    end
  end

  def generate_encrypted_token(attribute)
    loop do
      raw = SecureRandom.hex 32
      raw = yield raw if block_given?
      enc = ::BCrypt::Password.create raw
      break [raw, enc] unless self.class.exists? attribute => enc
    end
  end

  # See: https://github.com/plataformatec/devise/blob/88724e10adaf9ffd1d8dbfbaadda2b9d40de756a/lib/devise/encryptor.rb?ts=2#L12
  def compare_encrypted_token(attribute, token)
    return false if token.blank?

    hashed_token = self.send attribute
    bcrypt = ::BCrypt::Password.new hashed_token
    token = ::BCrypt::Engine.hash_secret token, bcrypt.salt

    secure_compare token, hashed_token
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
