class UserMailer < ApplicationMailer
  default from: "Keygen Support <hello@keygen.sh>"

  def password_reset(user:, token:)
    @user, @token = user, token

    mail to: user.email, subject: "Password reset requested for Keygen account"
  end
end
