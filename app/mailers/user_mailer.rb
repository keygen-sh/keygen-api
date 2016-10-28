class UserMailer < ApplicationMailer

  def password_reset(user:, token:)
    @user, @token = user, token

    mail to: user.email, subject: "Password reset requested"
  end
end
