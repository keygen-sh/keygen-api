module PasswordResetable
  extend ActiveSupport::Concern
  include Tokenable

  def send_password_reset
    self.password_reset_sent_at = Time.zone.now
    self.password_reset_token   = generate_token :password_reset_token
    save

    UserMailer.password_reset(self).deliver_later
  end
end
