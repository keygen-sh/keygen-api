class Token < ApplicationRecord
  belongs_to :account
  belongs_to :bearer, polymorphic: true

  before_create :generate_tokens

  def reset!
    generate_tokens
    self.save
  end

  private

  def generate_tokens
    self.auth_token  = generate_token_for :token, :auth_token
    self.reset_token = generate_token_for :token, :reset_token
  end
end
