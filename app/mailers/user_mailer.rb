# frozen_string_literal: true

class UserMailer < ApplicationMailer
  default from: "Keygen <noreply@keygen.sh>"
  layout "user_mailer"

  def password_reset(user:, token:)
    @user, @token = user, token
    @account = @user.account
    @expiration_date = @user.password_reset_sent_at + 24.hours

    mail to: user.email, reply_to: @account.email, subject: "Password reset requested for your #{@account.name} account"
  end
end
