module AuthToken
  extend ActiveSupport::Concern

  included do
    before_create :create_auth_tokens
  end

  def reset_auth_tokens!
    create_auth_tokens
    save
  end

  private

  def create_auth_tokens
    self.auth_token       = generate_token_for :user, :auth_token
    self.reset_auth_token = generate_token_for :user, :reset_auth_token
  end
end
