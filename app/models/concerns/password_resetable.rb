module PasswordResetable
  extend ActiveSupport::Concern
  include Tokenable

  def send_password_reset_email
    token, enc = generate_encrypted_token :password_reset_token do |token|
      "#{account.id.delete "-"}.#{id.delete "-"}.#{token}"
    end

    self.password_reset_sent_at = Time.zone.now
    self.password_reset_token   = enc
    save

    UserMailer.password_reset(user: self, token: token).deliver_later
  end
end
