module TokenAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_create :create_token
  end

  private

  def create_token
    self.token = Token.new account: account, bearer: self
  end
end
