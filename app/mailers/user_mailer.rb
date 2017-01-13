class UserMailer < ApplicationMailer
  default from: "Keygen Support <hello@keygen.sh>"

  def password_reset(user:, token:)
    @user, @token = user, token
    @account = @user.account

    mail to: user.email, subject: "Password reset requested for your #{@account.name} account"
  end
end
