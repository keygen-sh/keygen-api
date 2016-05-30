module AuthToken
  extend ActiveSupport::Concern

  included do
    before_create :create_auth_tokens!
  end

  def reset_auth_tokens!
    create_auth_tokens!
    save
  end

  protected

  def generate_token(token_name)
    loop do
      token = SecureRandom.hex
      break token unless User.exists? "#{token_name}": token
    end
  end

  private

  def create_auth_tokens!
    self.auth_token       = generate_token :auth_token
    self.reset_auth_token = generate_token :reset_auth_token
  end
end
