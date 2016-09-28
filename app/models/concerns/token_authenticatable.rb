module TokenAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_create :create_token

    delegate :add_role,    to: :token
    delegate :remove_role, to: :token
    delegate :has_role?,   to: :token
  end

  private

  def create_token
    self.token = Token.new account: account, bearer: self
  end
end
