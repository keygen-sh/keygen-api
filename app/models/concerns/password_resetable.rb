# frozen_string_literal: true

module PasswordResetable
  extend ActiveSupport::Concern
  include Tokenable

  def generate_password_reset_token
    token, enc = generate_hashed_token :password_reset_token, version: "v1" do |token|
      "#{account.id.delete "-"}.#{id.delete "-"}.#{token}"
    end

    self.password_reset_sent_at = Time.current
    self.password_reset_token   = enc
    save

    token
  end

  def send_password_reset_email(token:)
    UserMailer.password_reset(user: self, token: token).deliver_later
  end
end
