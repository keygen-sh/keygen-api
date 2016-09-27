module Tokenable
  extend ActiveSupport::Concern

  def generate_token(attribute)
    loop do
      token = SecureRandom.hex
      break token unless self.class.exists? attribute => token
    end
  end
end
