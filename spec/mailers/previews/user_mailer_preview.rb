# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview

  def password_reset
    token, enc = user.generate_hashed_token(:password_reset_token, length: 24)

    user.password_reset_sent_at = Time.zone.now
    user.password_reset_token   = enc

    UserMailer.password_reset user: user, token: token
  end

  private

  def user
    @user ||= User.first
  end
end
