class Token < ApplicationRecord
  rolify strict: true

  belongs_to :account
  belongs_to :bearer, polymorphic: true

  before_create :generate_tokens

  alias_method :can?, :has_role?

  def reset!
    generate_tokens
    self.save
  end

  private

  def generate_tokens
    self.auth_token  = generate_token :auth_token
    self.reset_token = generate_token :reset_token
  end
end
