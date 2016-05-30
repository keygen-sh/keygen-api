module PasswordReset
  extend ActiveSupport::Concern

  included do
    before_create :create_password_reset_token!
  end

  def send_password_reset
    self.password_reset_sent_at = Time.zone.now
    create_password_reset_token!
    save

    UserMailer.password_reset(self).deliver
  end

  protected

  def generate_token(token_name)
    loop do
      token = SecureRandom.hex
      break token unless User.exists? "#{token_name}": token
    end
  end

  private

  def create_password_reset_token!
    self.password_reset_token = generate_token :password_reset_token
  end
end
