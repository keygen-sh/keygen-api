class UserMailer < ApplicationMailer

  def password_reset(user, token)
    @user, @token = user, token
    mail to: user.email, subject: "Password Reset"
  end

  def account_activation(user, token)
    @user, @token = user, token
    mail to: user.email, subject: "Account Activation"
  end
end
