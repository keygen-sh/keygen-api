class Token < ApplicationRecord
  include Rolifiable

  belongs_to :account
  belongs_to :bearer, polymorphic: true

  before_create :generate_tokens

  def reset!
    generate_tokens
    save
  end

  private

  def generate_tokens
    self.auth_token  = generate_token :auth_token
    self.reset_token = generate_token :reset_token
  end
end
