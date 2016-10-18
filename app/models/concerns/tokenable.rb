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
      enc = BCrypt::Password.create raw
      break [raw, enc] unless self.class.exists? attribute => enc
    end
  end

  def compare_encrypted_token(attribute, token)
    enc = BCrypt::Password.new self.send(attribute)
    enc == token
  rescue
    false
  end
end
