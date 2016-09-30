module Tokenable
  extend ActiveSupport::Concern

  def generate_token(attribute, &block)
    loop do
      token = SecureRandom.hex
      token = yield token if block_given?
      break token unless self.class.exists? attribute => token
    end
  end
end
