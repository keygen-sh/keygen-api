module PasswordReset
  extend ActiveSupport::Concern

  included do
    before_create :create_password_reset_token
  end

  def send_password_reset
    self.password_reset_sent_at = Time.zone.now
    create_password_reset_token
    save

    UserMailer.password_reset(self).deliver_later
  end

  def reset_password_reset_token!
    create_password_reset_token
    save
  end

  private

  def create_password_reset_token
    self.password_reset_token = generate_token_for :user, :password_reset_token
  end
end
